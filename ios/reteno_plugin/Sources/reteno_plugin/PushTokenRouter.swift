import Foundation

/// Serializes push-token routing until the Flutter-selected token mode and the
/// native Reteno SDK are both ready.
///
/// The router deliberately keeps token source metadata. Reteno's native token
/// API accepts an untyped string, so forwarding a token from the wrong source
/// cannot be corrected or validated after it leaves this boundary.
final class PushTokenRouter {
    enum Mode: String {
        case automatic
        case manual
        case external
    }

    enum Source: String, Hashable {
        case apns
        case firebaseManaged
        case applicationManaged
    }

    enum RoutingResult: Equatable {
        case none
        case buffered
        case forwarded(String)
        case duplicate(String)
        case ignoredEmptyToken
        case ignoredSource(Source, Mode)
    }

    enum ConfigurationError: LocalizedError, Equatable {
        case modeAlreadyConfigured(configured: Mode, requested: Mode)

        var errorDescription: String? {
            switch self {
            case let .modeAlreadyConfigured(configured, requested):
                return "Push-token mode is already configured as \(configured.rawValue) and cannot be changed to \(requested.rawValue)."
            }
        }
    }

    typealias Sink = (String) -> Void

    private struct PendingToken {
        let value: String
        let source: Source
        let sequence: UInt64
    }

    private let queue: DispatchQueue
    private let queueKey = DispatchSpecificKey<UInt8>()
    private let queueValue: UInt8 = 1
    private let sink: Sink

    private var mode: Mode?
    private var retenoIsReady = false
    private var pendingTokens: [Source: PendingToken] = [:]
    private var nextSequence: UInt64 = 0
    private var lastForwardedValue: String?

    init(
        queueLabel: String = "com.reteno.flutter.push-token-router",
        sink: @escaping Sink
    ) {
        queue = DispatchQueue(label: queueLabel)
        self.sink = sink
        queue.setSpecific(key: queueKey, value: queueValue)
    }

    var configuredMode: Mode? {
        serialized { mode }
    }

    var isReady: Bool {
        serialized { retenoIsReady }
    }

    var lastForwardedToken: String? {
        serialized { lastForwardedValue }
    }

    /// Selects the token mode exactly once. Repeating the same mode is
    /// idempotent; attempting to switch modes fails without changing state.
    @discardableResult
    func configure(mode requestedMode: Mode) throws -> RoutingResult {
        try serialized {
            if let configuredMode = mode {
                guard configuredMode == requestedMode else {
                    throw ConfigurationError.modeAlreadyConfigured(
                        configured: configuredMode,
                        requested: requestedMode
                    )
                }
                return .none
            }

            mode = requestedMode
            pendingTokens = pendingTokens.reduce(into: [:]) { filtered, entry in
                guard Self.isAllowed(source: entry.key, in: requestedMode) else {
                    return
                }
                filtered[entry.key] = entry.value
            }

            return flushPendingTokenIfPossible()
        }
    }

    /// Marks the native Reteno SDK ready. This is idempotent and forwards at
    /// most one buffered token: the newest token from an allowed source.
    @discardableResult
    func markReady() -> RoutingResult {
        serialized {
            guard !retenoIsReady else {
                return .none
            }

            retenoIsReady = true
            return flushPendingTokenIfPossible()
        }
    }

    /// Routes a token according to its explicit source. Before configuration,
    /// the latest value for every source is buffered independently. Once a mode
    /// is selected, values from incompatible sources are never buffered or sent.
    @discardableResult
    func receive(_ token: String, from source: Source) -> RoutingResult {
        serialized {
            guard !token.isEmpty else {
                return .ignoredEmptyToken
            }

            nextSequence &+= 1
            let pendingToken = PendingToken(
                value: token,
                source: source,
                sequence: nextSequence
            )

            guard let configuredMode = mode else {
                pendingTokens[source] = pendingToken
                return .buffered
            }

            guard Self.isAllowed(source: source, in: configuredMode) else {
                pendingTokens.removeValue(forKey: source)
                return .ignoredSource(source, configuredMode)
            }

            guard retenoIsReady else {
                pendingTokens[source] = pendingToken
                return .buffered
            }

            return forwardIfNeeded(token)
        }
    }

    private func flushPendingTokenIfPossible() -> RoutingResult {
        guard retenoIsReady, let configuredMode = mode else {
            return .none
        }

        let newestAllowedToken = pendingTokens.values
            .filter { Self.isAllowed(source: $0.source, in: configuredMode) }
            .max { lhs, rhs in lhs.sequence < rhs.sequence }

        pendingTokens.removeAll()

        guard let token = newestAllowedToken else {
            return .none
        }

        return forwardIfNeeded(token.value)
    }

    private func forwardIfNeeded(_ token: String) -> RoutingResult {
        guard token != lastForwardedValue else {
            return .duplicate(token)
        }

        lastForwardedValue = token
        sink(token)
        return .forwarded(token)
    }

    private static func isAllowed(source: Source, in mode: Mode) -> Bool {
        switch (mode, source) {
        case (.automatic, .apns):
            return true
        case (.manual, .firebaseManaged),
             (.manual, .applicationManaged):
            return true
        case (.external, .applicationManaged):
            return true
        default:
            return false
        }
    }

    private func serialized<T>(_ operation: () throws -> T) rethrows -> T {
        if DispatchQueue.getSpecific(key: queueKey) == queueValue {
            return try operation()
        }
        return try queue.sync(execute: operation)
    }
}
