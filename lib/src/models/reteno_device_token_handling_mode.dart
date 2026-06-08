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
}
