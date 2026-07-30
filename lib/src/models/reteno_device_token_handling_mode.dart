enum RetenoDeviceTokenHandlingMode {
  /// iOS APNs token handling managed by the native Reteno SDK.
  ///
  /// Use this when the Reteno mobile app is configured for APN on iOS.
  automatic,

  /// iOS Firebase Messaging token handling managed by the Flutter plugin.
  ///
  /// Use this when the Reteno mobile app is configured as FCM-only.
  /// Android always uses native automatic token handling.
  manual,

  /// Push token handling fully owned by the Flutter application.
  ///
  /// On iOS, the Reteno plugin does not assign a Firebase Messaging delegate,
  /// request an FCM token, or set the APNs token on Firebase. The application
  /// must pass its current FCM token using `Reteno().setPushToken` and repeat
  /// the call whenever Firebase refreshes the token.
  ///
  /// Android always uses native automatic token handling.
  external,
}
