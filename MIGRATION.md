# Migration Guide

## Flutter-first initialization

Reteno now supports a Flutter-first setup flow where the SDK is initialized from Dart.

```dart
await Reteno().initialize(
  accessKey: '<your_access_key>',
  options: RetenoInitOptions(
    lifecycleTrackingOptions: LifecycleTrackingOptions.all(),
  ),
);
```

`Reteno().initWith(...)` remains available as a backward-compatible alias, but `initialize(...)` is the recommended setup.

## Android migration notes

If your app has Reteno-only native wiring from older versions, remove it:

1. Remove custom `FirebaseMessagingService` classes that were added only for Reteno.
2. Remove Reteno-specific `MESSAGING_EVENT` service declarations from app manifest.
3. Remove legacy native Reteno bootstrap if it was used only for Flutter plugin setup.

The plugin now registers Reteno messaging bridge service from the plugin manifest.

### If your app must keep custom FCM service

Some apps already have business logic inside custom `FirebaseMessagingService`.
In this case:

1. Keep a single app-level `MESSAGING_EVENT` service.
2. Make that service inherit from `RetenoFirebaseMessagingServiceBridge`.
3. Call `super.onNewToken(...)` and `super.onMessageReceived(...)`.
4. Remove plugin bridge service in app manifest with `tools:node="remove"`.

Use `Reteno().diagnose()` to catch configuration problems:

- `FCM_MESSAGING_SERVICE_MISSING`
- `RETENO_MESSAGING_SERVICE_MISSING`
- `FCM_MESSAGING_SERVICE_CONFLICT`
- `FCM_TOKEN_MISSING`
- `FCM_TOKEN_FETCH_FAILED`

## iOS migration notes

If your app previously initialized Reteno from `AppDelegate`, move initialization to Flutter:

1. Remove manual `Reteno.start(...)` from `AppDelegate`.
2. Keep required Notification Service Extension + App Group setup from native iOS guide.
3. If you use carousel or GIF push UI, also add `NotificationContentExtension`.
4. Call `Reteno().initialize(...)` from Flutter startup.
5. Use `Reteno().requestPushPermission()` to request permission and register for remote notifications.

`NotificationServiceExtension` + App Group remain mandatory for full iOS Reteno push behavior. `NotificationContentExtension` is additionally required for carousel/GIF push UI.

### Migrating to 1.11.0

Select the final iOS token mode in the first `initialize()` call. Repeating the
same mode is supported, but changing it after initialization now returns an
error instead of leaving Dart and native token ownership out of sync.

- `automatic` forwards only APNs tokens.
- `manual` forwards current and refreshed plugin-managed FCM tokens without
  replacing the application's Firebase Messaging delegate.
- `external` forwards only FCM tokens supplied by the application through
  `setPushToken()`.

Early APNs callbacks are now source-aware and cannot be flushed into either FCM
mode. Remove Reteno-only `MessagingDelegate` workarounds. From every legacy
notification-center multiplexer, remove the leg that forwards callbacks to
`Reteno.userNotificationService`, even when that multiplexer must remain for
other SDKs; otherwise Reteno processes the same notification twice. The 1.11.0
bridge coordinates Reteno with the surrounding FlutterFire/application
delegate chain in every token mode. Any delegate installed later must still
forward to the previous delegate.

`customDeviceId` is now supported on iOS. Its asynchronous provider is awaited
once before native initialization; returning `null` keeps the default device
ID. Enabling a non-null custom ID on an existing installation can replace its
stored default ID, so use a stable value and validate the identity migration
before rollout.

## Verify migration

Run diagnostics after initialization:

```dart
final issues = await Reteno().diagnose();
```

Expected result is `[]`.

If not empty, inspect returned issue codes and resolve integration conflicts first.
