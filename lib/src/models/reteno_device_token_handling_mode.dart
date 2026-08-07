enum RetenoDeviceTokenHandlingMode {
  /// iOS APNs token handling managed automatically by the Reteno bridge.
  ///
  /// Use this when the Reteno mobile app is configured for APN on iOS.
  /// Notification callbacks are chained with an existing application delegate.
  automatic,

  /// iOS Firebase Messaging token handling managed by the Flutter plugin.
  ///
  /// Use this when the Reteno mobile app is configured as FCM-only.
  /// The plugin observes Firebase token refreshes without replacing the
  /// application's Firebase Messaging delegate.
  /// Existing integrations may still call `setPushToken`, but new code should
  /// not mix explicit tokens with this plugin-managed flow.
  /// Android always uses native automatic token handling.
  manual,

  /// Push token handling fully owned by the Flutter application.
  ///
  /// On iOS, the Reteno plugin does not assign a Firebase Messaging delegate,
  /// request an FCM token, or set the APNs token on Firebase. The application
  /// must pass its current FCM token using `Reteno().setPushToken` and repeat
  /// the call whenever Firebase refreshes the token.
  /// Reteno foreground, click, and action callbacks remain enabled because
  /// notification handling is independent from token ownership.
  ///
  /// Android always uses native automatic token handling.
  external,
}
