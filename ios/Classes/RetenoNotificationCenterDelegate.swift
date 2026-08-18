import Foundation
import Reteno
import UserNotifications

/// Coordinates Reteno notification handling with a delegate that was already
/// installed on `UNUserNotificationCenter`.
///
/// `UNUserNotificationCenter` does not retain its delegate. The owner that
/// installs this coordinator must therefore keep the returned instance alive
/// for as long as notification callbacks are required.
@available(iOSApplicationExtension, unavailable)
final class RetenoNotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    private static let interactionIdKey = "es_interaction_id"
    private static let defaultCompletionTimeout: TimeInterval = 2
    private static let fallbackQueue = DispatchQueue(
        label: "com.reteno.flutter.notification-delegate-fallback",
        qos: .userInitiated
    )

    private let retenoDelegate: UserNotificationService
    private let completionTimeout: TimeInterval
    private weak var previousDelegate: UNUserNotificationCenterDelegate?

    /// Reports whether the notification center is currently owned by a
    /// coordinator. Reteno callbacks are unreachable while this is false.
    /// Must be called on the main thread.
    static func isInstalled(on center: UNUserNotificationCenter = .current()) -> Bool {
        center.delegate is RetenoNotificationCenterDelegate
    }

    /// Installs a coordinator around the notification center's current
    /// delegate. Calling this while an instance is already installed is
    /// idempotent and returns that instance.
    ///
    /// The caller must retain the returned coordinator strongly.
    @discardableResult
    static func install(
        on center: UNUserNotificationCenter = .current(),
        completionTimeout: TimeInterval = defaultCompletionTimeout
    ) -> RetenoNotificationCenterDelegate {
        let installOnMain = {
            if let installed = center.delegate as? RetenoNotificationCenterDelegate {
                return installed
            }

            let retenoDelegate = Reteno.userNotificationService
            let currentDelegate = center.delegate
            let downstream: UNUserNotificationCenterDelegate?

            if let currentDelegate = currentDelegate,
               (currentDelegate as AnyObject) === (retenoDelegate as AnyObject) {
                // Reteno may already have installed its service directly. The
                // coordinator invokes it explicitly, so retaining it as the
                // downstream delegate would process every Reteno callback twice.
                downstream = nil
            } else {
                downstream = currentDelegate
            }

            let coordinator = RetenoNotificationCenterDelegate(
                retenoDelegate: retenoDelegate,
                previousDelegate: downstream,
                completionTimeout: completionTimeout
            )
            center.delegate = coordinator
            return coordinator
        }

        if Thread.isMainThread {
            return installOnMain()
        }

        return DispatchQueue.main.sync(execute: installOnMain)
    }

    init(
        retenoDelegate: UserNotificationService = Reteno.userNotificationService,
        previousDelegate: UNUserNotificationCenterDelegate?,
        completionTimeout: TimeInterval = defaultCompletionTimeout
    ) {
        self.retenoDelegate = retenoDelegate
        self.completionTimeout = max(0.1, completionTimeout)

        if let previousCoordinator = previousDelegate as? RetenoNotificationCenterDelegate {
            // Do not create an obvious coordinator-to-coordinator chain: both
            // coordinators would invoke the same Reteno singleton.
            self.previousDelegate = previousCoordinator.previousDelegate
        } else if let previousDelegate = previousDelegate,
                  (previousDelegate as AnyObject) !== (retenoDelegate as AnyObject) {
            self.previousDelegate = previousDelegate
        }

        super.init()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let systemCompletion = RetenoOnce(completionHandler)
        let retenoFallback = RetenoLockedValue(UNNotificationPresentationOptions())
        let isRetenoNotification = isRetenoPayload(notification.request.content.userInfo)
        let downstream = downstreamDelegate(respondingTo: #selector(
            UNUserNotificationCenterDelegate.userNotificationCenter(
                _:willPresent:withCompletionHandler:
            )
        ))

        scheduleFallback {
            systemCompletion.call(retenoFallback.value)
        }

        if isRetenoNotification {
            let retenoCompletion = RetenoOnce<UNNotificationPresentationOptions> { options in
                retenoFallback.value = options
                if downstream == nil {
                    systemCompletion.call(options)
                }
            }

            retenoDelegate.userNotificationCenter(
                center,
                willPresent: notification,
                withCompletionHandler: { options in
                    retenoCompletion.call(options)
                }
            )
        }

        guard let downstream = downstream else {
            if !isRetenoNotification {
                systemCompletion.call([])
            }
            return
        }

        // The application's pre-existing delegate is authoritative for
        // presentation. Reteno's result is retained only as a bounded fallback.
        let downstreamCompletion = RetenoOnce<UNNotificationPresentationOptions> { options in
            systemCompletion.call(options)
        }
        downstream.userNotificationCenter?(
            center,
            willPresent: notification,
            withCompletionHandler: { options in
                downstreamCompletion.call(options)
            }
        )
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let isRetenoNotification = isRetenoPayload(response.notification.request.content.userInfo)
        let downstream = downstreamDelegate(respondingTo: #selector(
            UNUserNotificationCenterDelegate.userNotificationCenter(
                _:didReceive:withCompletionHandler:
            )
        ))
        let participantCount = (isRetenoNotification ? 1 : 0) + (downstream == nil ? 0 : 1)

        guard participantCount > 0 else {
            completionHandler()
            return
        }

        let barrier = RetenoCompletionBarrier(
            participantCount: participantCount,
            completion: completionHandler
        )
        scheduleFallback {
            barrier.forceComplete()
        }

        if isRetenoNotification {
            let retenoCompletion = RetenoOnce<Void> { _ in
                barrier.leave()
            }
            retenoDelegate.userNotificationCenter(
                center,
                didReceive: response,
                withCompletionHandler: {
                    retenoCompletion.call(())
                }
            )
        }

        if let downstream = downstream {
            let downstreamCompletion = RetenoOnce<Void> { _ in
                barrier.leave()
            }
            downstream.userNotificationCenter?(
                center,
                didReceive: response,
                withCompletionHandler: {
                    downstreamCompletion.call(())
                }
            )
        }
    }

    @available(iOS 12.0, *)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        openSettingsFor notification: UNNotification?
    ) {
        let selector = #selector(
            UNUserNotificationCenterDelegate.userNotificationCenter(_:openSettingsFor:)
        )
        downstreamDelegate(respondingTo: selector)?
            .userNotificationCenter?(center, openSettingsFor: notification)
    }

    private func isRetenoPayload(_ userInfo: [AnyHashable: Any]) -> Bool {
        guard let interactionId = userInfo[Self.interactionIdKey] as? String else {
            return false
        }
        return !interactionId.isEmpty
    }

    private func downstreamDelegate(respondingTo selector: Selector) -> UNUserNotificationCenterDelegate? {
        guard let delegate = previousDelegate,
              (delegate as AnyObject) !== (self as AnyObject),
              (delegate as AnyObject) !== (retenoDelegate as AnyObject),
              delegate.responds(to: selector) else {
            return nil
        }
        return delegate
    }

    private func scheduleFallback(_ fallback: @escaping () -> Void) {
        Self.fallbackQueue.asyncAfter(
            deadline: .now() + completionTimeout,
            execute: fallback
        )
    }
}

private final class RetenoOnce<Value> {
    private let lock = NSLock()
    private var completion: ((Value) -> Void)?

    init(_ completion: @escaping (Value) -> Void) {
        self.completion = completion
    }

    func call(_ value: Value) {
        let completionToCall: ((Value) -> Void)?

        lock.lock()
        completionToCall = completion
        completion = nil
        lock.unlock()

        completionToCall?(value)
    }
}

private final class RetenoLockedValue<Value> {
    private let lock = NSLock()
    private var storedValue: Value

    init(_ value: Value) {
        storedValue = value
    }

    var value: Value {
        get {
            lock.lock()
            defer { lock.unlock() }
            return storedValue
        }
        set {
            lock.lock()
            storedValue = newValue
            lock.unlock()
        }
    }
}

private final class RetenoCompletionBarrier {
    private let lock = NSLock()
    private var remainingParticipants: Int
    private var completion: (() -> Void)?

    init(participantCount: Int, completion: @escaping () -> Void) {
        remainingParticipants = participantCount
        self.completion = completion
    }

    func leave() {
        let completionToCall: (() -> Void)?

        lock.lock()
        if completion == nil {
            completionToCall = nil
        } else {
            remainingParticipants -= 1
            if remainingParticipants == 0 {
                completionToCall = completion
                completion = nil
            } else {
                completionToCall = nil
            }
        }
        lock.unlock()

        completionToCall?()
    }

    func forceComplete() {
        let completionToCall: (() -> Void)?

        lock.lock()
        completionToCall = completion
        completion = nil
        lock.unlock()

        completionToCall?()
    }
}
