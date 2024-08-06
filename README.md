# reteno_plugin

Reteno Flutter SDK

## Documentation
[Official documentation](https://docs.reteno.com/reference/flutter-sdk)
## Installation

### iOS
#### Installation

1. Follow `Step 1` described in iOS SDK setup guide: [link](https://docs.reteno.com/reference/ios#step-1-add-the-notification-service-extension)


2. Modify your cocoapod file to contain next dependencies:
```

target 'NotificationServiceExtension' do
  pod 'Reteno', '2.0.9'

end

target 'RetenoSdkExample' do
  ...
  pod 'Reteno', '2.0.9'
end

```

3. Run next command from root of your project:

```sh
flutter pub add reteno_plugin
```
4. Next step for iOS is to call `Reteno.start` inside of your `AppDelegate` file. If you have migrated to `AppDelegate.swift`, follow `Step 3` in iOS SDK setup guide: [link](https://docs.reteno.com/reference/ios#step-3-import-reteno-into-your-app-delegate)

### Android
#### Installation


1. Run next command from root of your project:

```sh
flutter pub add reteno_plugin
```
2. Add mavenCentral repository in your project level `build.gradle`:
```groovy
buildscript {
    repositories {
        mavenCentral()
    }
...
}
```
3. Also you may need to increase `minSdkVersion` in project level `build.gradle` to `21`, since `Reteno` uses this version as minimal;

#### Setting up SDK

1. Follow `Step 1` described in Android SDK setup guide: [link](https://docs.reteno.com/reference/android-sdk-setup#step-1-make-sure-to-enable-androidx-in-your-gradleproperties-file);

2. Follow `Step 2` described in Android SDK setup guide: [link](https://docs.reteno.com/reference/android-sdk-setup#step-2-make-sure-to-add-comretenofcm-and-firebase-dependencies-in-buildgradle);

3. Edit your MainApplication class and provider API Access-Key at SDK initialization.

Below is sample code you can add to your application class which gets you started with `RetenoSDK`.

```kotlin
package [com.YOUR_PACKAGE];

import com.reteno.core.Reteno
import com.reteno.core.RetenoApplication
import com.reteno.core.RetenoImpl
import io.flutter.app.FlutterApplication

class CustomApplication : FlutterApplication(), RetenoApplication {
    override fun onCreate() {
        super.onCreate()
        retenoInstance = RetenoImpl(this, "<your_access_key>")
    }

    private lateinit var retenoInstance: Reteno
    override fun getRetenoInstance(): Reteno {
        return retenoInstance
    }
}
```

3. Optionally (Android Only), you can make late initialization with config

```kotlin
class CustomApplication : FlutterApplication(), RetenoApplication {
    override fun onCreate() {
        super.onCreate()
        retenoInstance = RetenoImpl(this, "<your_access_key>")
    }

    private lateinit var retenoInstance: Reteno
    override fun getRetenoInstance(): Reteno {
        return retenoInstance
    }
}
```
in Flutter project

```dart
await Reteno().initWith(
      accessKey: '<your_access_key>',
      userId: '<your_user_id>',
      isPausedInAppMessages: true,
      lifecycleTrackingOptions: LifecycleTrackingOptions.all(),
    );
```

4. Follow `Step 5` described in Android SDK setup guide: [link](https://docs.reteno.com/reference/android-sdk-setup#step-5-make-sure-to-set-up-your-firebase-application-for-firebase-cloud-messaging);


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

## Tracking user behaviour

### Track Custom Events

`Reteno SDK` provides ability to track custom events.

```dart
RetenoPlugin().logEvent({required RetenoCustomEvent event});
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

await RetenoPlugin().logEvent(event: event);
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

## License

MIT
