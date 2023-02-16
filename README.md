# reteno_plugin

Reteno Flutter SDK

## Documentation 
[Official documentation](https://docs.reteno.com/reference/flutter-sdk)
## Installation

- [iOS](./docs/ios.md)
- [Android](./docs/android.md)

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

**Note**

`LanguageCode`

The tags for identifying language must be in compliance with [RFC 5646](https://www.rfc-editor.org/rfc/rfc5646.html). The primary language subtag must comply with the [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) format. Example: de-AT.

`TimeZone`

The time zone format must comply with [TZ database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones). Example: `Europe/Kyiv`.


## License

MIT
