# reteno_plugin

Reteno Flutter SDK

## Documentation
[Official documentation](https://docs.reteno.com/reference/flutter-sdk)
[Migration guide](./MIGRATION.md)
## Installation

### 1. Add package

```sh
flutter pub add reteno_plugin
```

### 2. Initialize SDK in Flutter

```dart
import 'package:reteno_plugin/reteno.dart';

await Reteno().initialize(
  accessKey: '<your_access_key>',
  options: RetenoInitOptions(
    lifecycleTrackingOptions: LifecycleTrackingOptions.all(),
    isDebug: false,
    deviceTokenHandlingMode: RetenoDeviceTokenHandlingMode.automatic,
  ),
);
```

### 3. Request push permission

```dart
final granted = await Reteno().requestPushPermission();
```

### 4. Verify integration diagnostics

```dart
final issues = await Reteno().diagnose();
// [] means integration checks passed
```

### iOS requirements

1. Add `NotificationServiceExtension` and follow iOS guide Step 1:
[https://docs.reteno.com/reference/ios#step-1-add-the-notification-service-extension](https://docs.reteno.com/reference/ios#step-1-add-the-notification-service-extension)
2. Add `pod 'Reteno', '2.6.2'` to app target and all Reteno notification extensions.
3. Configure App Group for app + extension.
4. Do not initialize Reteno manually from `AppDelegate` when using this Flutter plugin. Initialization should be done via `Reteno().initialize(...)`.
5. For push image carousel/GIF UI on iOS, add `NotificationContentExtension` with `RetenoCarouselNotificationViewController` and categories `ImageCarousel`/`ImageGif`.

`NotificationServiceExtension` + App Group are required for full iOS Reteno push functionality.

### Android requirements

1. Enable AndroidX and complete Firebase setup from Android guide:
[https://docs.reteno.com/reference/android-sdk-setup](https://docs.reteno.com/reference/android-sdk-setup)
2. `minSdkVersion` must be at least `21`.
3. Do not add custom `FirebaseMessagingService` only for Reteno. The plugin handles Reteno push service wiring internally.

### Android advanced setup (if your app already has custom `FirebaseMessagingService`)

Use this only when you already have app-specific FCM logic and need to keep it.

Rules:

1. Your app must have exactly one app-level `MESSAGING_EVENT` service.
2. That service should inherit from `RetenoFirebaseMessagingService`.
3. `onNewToken` and `onMessageReceived` must call `super`.
4. Remove plugin bridge service from manifest merge in the app module.

Manifest example:

```xml
<application xmlns:tools="http://schemas.android.com/tools">
    <service
        android:name="com.reteno.reteno_plugin.RetenoFirebaseMessagingServiceBridge"
        tools:node="remove" />

    <service
        android:name=".MyMessagingService"
        android:exported="false">
        <intent-filter>
            <action android:name="com.google.firebase.MESSAGING_EVENT" />
        </intent-filter>
    </service>
</application>
```

Service example:

```kotlin
import com.google.firebase.messaging.RemoteMessage
import com.reteno.fcm.RetenoFirebaseMessagingService

class MyMessagingService : RetenoFirebaseMessagingService() {
    override fun onNewToken(token: String) {
        super.onNewToken(token)
        // your token logic
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)
        if (!isRetenoMessage(message)) {
            // your non-Reteno message logic
        }
    }
}
```

### Diagnose codes

`Reteno().diagnose()` may return:

| Code | Meaning |
| --- | --- |
| `SDK_NOT_INITIALIZED` | Reteno SDK has not been initialized yet |
| `NOTIFICATIONS_DISABLED` | Notifications are disabled in OS settings |
| `PUSH_PERMISSION_DENIED` | Notification runtime permission denied |
| `PUSH_PERMISSION_NOT_DETERMINED` | iOS permission dialog not shown yet |
| `REMOTE_NOTIFICATIONS_NOT_REGISTERED` | iOS permission granted but APNs registration not completed |
| `FCM_MESSAGING_SERVICE_MISSING` | Android has no active `MESSAGING_EVENT` handler |
| `RETENO_MESSAGING_SERVICE_MISSING` | Android has no Reteno push handler among `MESSAGING_EVENT` services |
| `FCM_MESSAGING_SERVICE_CONFLICT` | Multiple app-level `MESSAGING_EVENT` services detected on Android |
| `FCM_TOKEN_MISSING` | Android SDK cannot get current FCM token |
| `FCM_TOKEN_FETCH_FAILED` | Android failed to fetch FCM token from Firebase SDK |

### Push troubleshooting (Android)

If Reteno Console says contact has no app token:

1. Ensure `Reteno().initialize(...)` is called on app startup before user update calls.
2. Request push permission (`Reteno().requestPushPermission()`).
3. Call `Reteno().setUserAttributes(userExternalId: ...)` for the same contact you target in Console.
4. Run `Reteno().diagnose()` and resolve all returned codes.
5. Verify app has only one effective app-level `MESSAGING_EVENT` service (or bridge + proper merge setup).


## Push notifications

### Getting initial notification

When you instantiate the app by clicking on a push notification, you may need to get its payload.
To do it, use the `getInitialNotification` method:

```dart
import 'package:reteno_plugin/reteno.dart';

final Reteno reteno = Reteno();

reteno.getInitialNotification().then((Map<String, dynamic>? payload) {
      // Process payload...
});

```

### Listening for new push notifications in an open app

When the app is open, you may need to track for new push notifications.
For that, the plugin provides the `onRetenoNotificationReceived` stream you can listen to:

```dart
import 'package:reteno_plugin/reteno.dart';

Reteno.onRetenoNotificationReceived.listen((Map<String, dynamic> payload) {
      // Process payload...
});

```

### Getting notification data when interacting with push

When you want to handle interaction with received notification you can use `onRetenoNotificationClicked` stream, so you can listen to it and receive notification data:

```dart
import 'package:reteno_plugin/reteno.dart';

Reteno.onRetenoNotificationClicked.listen((Map<String, dynamic> payload) {
      // Process payload...
});

```

### Push notification actions

When you want to handle push notification actions you can use `onUserNotificationAction` stream, so you can listen to it and receive notification action data:

```dart
import 'package:reteno_plugin/reteno.dart';

    Reteno.onUserNotificationAction.listen((event) {
      print('$_retenoPluginLogTag: onUserNotificationAction: ${event.toString()}');
    });

```

## Tracking user behaviour

### Track Custom Events

`Reteno SDK` provides ability to track custom events.

```dart
Reteno().logEvent({required RetenoCustomEvent event});
```

###### Custom Event model:
```dart
class RetenoCustomEvent {
  RetenoCustomEvent({
    required this.eventTypeKey,
    required this.dateOccurred,
    this.forcePush = false,
    required this.parameters,
  });

  final String eventTypeKey;
  final DateTime dateOccurred;
  final List<RetenoCustomEventParameter> parameters;
  final bool forcePush;
}
```

- eventTypeKey - key qualifier of the event (provided by appDeveloper, confirmed by marketing team).

- dateOccurred - time when event occurred (Date should be in [ISO8601](https://en.wikipedia.org/wiki/ISO_8601) format)

- parameters - list of parameters, which describe the event

- forcePush - `iOS`-only feature; Please read more about it [here](https://github.com/reteno-com/reteno-mobile-ios-sdk/blob/b8a9c60da9a41dc7cb22260b6ef8e5a842752b5e/Reteno/Sources/Core/Reteno.swift#L47)

###### Parameter model containt key/value fields to describe the parameter:

```dart
class RetenoCustomEventParameter {
  RetenoCustomEventParameter(this.name, this.value);

  final String name;
  final String? value;
}
```

###### Example of usage:
```dart
final dateOccured = DateTime.now();
final event = RetenoCustomEvent(
  eventTypeKey: eventTypeName,
  dateOccurred: dateOccured,
  parameters: [
    RetenoCustomEventParameter(<parameter_name>, <parameter_value>)
  ],
  forcePush: true|false,
);

await Reteno().logEvent(event: event);
```


## Tracking user information

You can track the user related information using external user ID and/or user attributes. For that, you have to add `userExternalId` and `setUserAttributes` to Reteno Flutter.

### Adding External User ID

External user ID is an ID you have assigned to a user in your system (external for 'Reteno').
You can add these in `Reteno` Flutter using the following method:

```dart
import 'package:reteno_plugin/reteno.dart';

final reteno = Reteno();
reteno.setUserAttributes(
  userExternalId: 'USER_ID',
  user: userInfo,
);
```

### Adding User Attributes

User attributes define the information you collect about contacts in your user base. For example, phone number, email address, language preference, geographic location.

You can add user attributes using the following method:

```dart
import 'package:reteno_plugin/reteno.dart';

final reteno = Reteno();
reteno.setUserAttributes(
  userExternalId: 'USER_ID',
  user: userInfo,
);
```



Structure of the `RetenoUser` object:

```dart
class RetenoUser {
  RetenoUser({
    this.subscriptionKeys,
    this.userAttributes,
    this.groupNamesExclude,
    this.groupNamesInclude,
  });

  final UserAttributes? userAttributes;
  final List<String>? subscriptionKeys;
  final List<String>? groupNamesInclude;
  final List<String>? groupNamesExclude;
}

class UserAttributes {
  UserAttributes({
    this.lastName,
    this.firstName,
    this.address,
    this.email,
    this.fields,
    this.languageCode,
    this.phone,
    this.timeZone,
  });
  final String? phone;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? languageCode;
  final String? timeZone;
  final Address? address;
  final List<UserCustomField>? fields;
}

class Address {
  Address({
    this.address,
    this.postcode,
    this.region,
    this.town,
  });
  final String? region;
  final String? town;
  final String? address;
  final String? postcode;
}

class UserCustomField {
  UserCustomField({
    required this.key,
    this.value,
  });
  final String key;
  final String? value;
}
```

### Anonymous User Attributes
>Available for reteno_plugin starting from version **1.1.0**
`Reteno` plugin allows tracking anonymous user attributes `(no externalUserId required)`. To set user attributes without externalUserId use method `setAnonymousUserAttributes()`:

```dart
Reteno.setAnonymousUserAttributes(AnonymousUserAttributes attributes);

**AnonymousUserAttributes** model:

```dart
class AnonymousUserAttributes {
  AnonymousUserAttributes({
    this.lastName,
    this.firstName,
    this.address,
    this.fields,
    this.languageCode,
    this.timeZone,
  });
  final String? firstName;
  final String? lastName;
  final String? languageCode;
  final String? timeZone;
  final Address? address;
  final List<UserCustomField>? fields;
}

```

> **Note**: you can't provide anonymous user attributes with **phone** or/and **email**. For that purpose use `setUserAttributes()` method with externalUserId


**Note**

`LanguageCode`

The tags for identifying language must be in compliance with [RFC 5646](https://www.rfc-editor.org/rfc/rfc5646.html). The primary language subtag must comply with the [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) format. Example: de-AT.

`TimeZone`

The time zone format must comply with [TZ database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones). Example: `Europe/Kyiv`.


**Note**
In versions before 1.2.2 you can not use [sentry_fltter](https://pub.dev/packages/sentry_flutter) due to sentry iOS versions mismatch. If you want to use sentry_flutter in your application. Please use `flutter_plugin : 1.2.2` and `sentry_flutter: 7.8.0`


## In-App Messages

### Pausing and Resuming In-App Messages

You can pause and resume in-app messages using the following methods:

```dart
// Pause in-app messages
Reteno.pauseInAppMessages(true);

// Resume in-app messages
Reteno.pauseInAppMessages(false);
```

### Listening for In-App Message Status Changes
```dart
  Reteno.onInAppMessageStatusChanged.listen((status) {
      switch (status) {
        case InAppShouldBeDisplayed():
          print('In-app should be displayed');
        case InAppIsDisplayed():
          print('In-app is displayed');
        case InAppShouldBeClosed(:final action):
          print('In-app should be closed $action');
        case InAppIsClosed(:final action):
          print('In-app is closed $action');
        case InAppReceivedError(:final errorMessage):
          print('In-app error: $errorMessage');
      }
    });
```

## Get recommended products

You can personalize the user experience and increase sales by adding recommendations of your goods and services to an app.

```dart
  final recommendations = await Reteno.getRecommendations(
    recomenedationVariantId: 'r1107v1482',
    productIds: ['240-LV09', '24-WG080'],
    categoryId: 'Default Category/Training/Video Download',
    filters: [RetenoRecomendationFilter(name: 'filter_name', values: ['filter_value'])],
    fields: ['productId', 'name', 'descr', 'imageUrl', 'price'],
  );
  ```

  ## Reteno App Inbox
  ### Downloading new messages
  ```dart
  final messages = await Reteno.appInbox.getAppInboxMessages();
  ```
  ### Marking message as opened
  ```dart
  Reteno.appInbox.markAsOpened(message.id);
  ```
  ### Marking all messages as opened
  ```dart
  Reteno.appInbox.markAllMessagesAsOpened();
  ```
  ### Obtaining messages count
  ```dart
  final count = await Reteno.appInbox.getAppInboxMessagesCount();
  ```
  ### Subscribing to messages count changes
  ```dart
  Reteno.appInbox.onMessagesCountChanged.listen((count) {
    print(count);
  });
  ```


## License

MIT
