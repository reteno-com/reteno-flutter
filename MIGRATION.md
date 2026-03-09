# Migration Guide

## Migrating to Flutter-first initialization

This plugin now supports a Flutter-first setup flow where Reteno is initialized from Dart.

```dart
await Reteno().initialize(
  accessKey: '<your_access_key>',
  options: RetenoInitOptions(
    lifecycleTrackingOptions: LifecycleTrackingOptions.all(),
  ),
);
```

## Android migration notes

If your app has Reteno-only native wiring from older versions, remove it:

1. Remove custom `FirebaseMessagingService` classes that were added only for Reteno.
2. Remove Reteno-specific `MESSAGING_EVENT` service declarations from app manifest.
3. Remove legacy `MainApplication` `RetenoApplication` bootstrap if it was used only for Flutter plugin setup.

The plugin now registers Reteno messaging bridge service from the plugin manifest.

### If your app must keep custom FCM service

Some apps already have business logic inside custom `FirebaseMessagingService`.
In this case:

1. Keep a single app-level `MESSAGING_EVENT` service.
2. Make that service inherit from `RetenoFirebaseMessagingService`.
3. Call `super.onNewToken(...)` and `super.onMessageReceived(...)`.
4. Remove plugin bridge service in app manifest with `tools:node="remove"`.

Use `Reteno().diagnose()` to catch configuration problems:

- `FCM_MESSAGING_SERVICE_MISSING`
- `RETENO_MESSAGING_SERVICE_MISSING`
- `FCM_MESSAGING_SERVICE_CONFLICT`
- `FCM_TOKEN_MISSING`
- `FCM_TOKEN_FETCH_FAILED`

## iOS migration notes

If your app previously initialized Reteno from `AppDelegate`, migrate to Dart initialization:

1. Remove manual `Reteno.start(...)` from `AppDelegate`.
2. Keep required Notification Service Extension + App Group setup from native iOS guide.
3. Call `Reteno().initialize(...)` from Flutter startup.
4. Use `Reteno().requestPushPermission()` to request permission and register for remote notifications.

`NotificationServiceExtension` + App Group remain mandatory for full iOS Reteno push behavior.

## Verify migration

Run diagnostics after initialization:

```dart
final issues = await Reteno().diagnose();
```

Expected result is `[]`.

If not empty, inspect returned issue codes and resolve integration conflicts first.

## Documentation sync checklist

If you publish this version, update both places:

1. `README.md` in this plugin repository.
2. Product docs page on `https://docs.reteno.com/docs`.

`MIGRATION.md` should also be committed and pushed with release changes, because it is the canonical upgrade reference for existing integrators.
