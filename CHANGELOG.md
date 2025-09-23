## 1.8.5
* Bump iOS sdk to 2.5.13

## 1.8.4
* Bump iOS sdk to 2.5.12

## 1.8.3
* Bump Android sdk to 2.8.4

## 1.8.2
* Bump Android sdk to 2.8.1
* Bump iOS sdk to 2.5.11
* Add `getRecommendationsJson` method.

## 1.8.1
* `Reteno.initWith` method now accepts `isDebug` parameter to enable debug mode (Android only).

## 1.8.0
* Android: not need create `CustomApplication` class. All initialization is done via `Reteno.initWith` method.
* Enhance `RetenoRecommendation` model with additional fields:
  - Add category, categoryAncestor, categoryLayout, categoryParent
  - Add dateCreatedAs, dateCreatedEs, dateModifiedAs
  - Add itemGroup, nameKeyword, productIdAlt
  - Add various tags fields (tagsBestseller, tagsCashback, etc.)
  - Add url field for product recommendations
* Make categoryId parameter optional in `getRecommendations` method


## 1.7.8
* Bump Android sdk to 2.7.4
* Fix Ecommerce Activity Tracking

## 1.7.7
* Bump Android sdk to 2.7.2
* Bump iOS sdk to 2.5.10
* customDeviceId parameter in Reteno initialization allow return null (Android only)

## 1.7.6
* Bump Android sdk to 2.6.3

## 1.7.5
* Add Ecommerce Activity Tracking `Reteno().logEcommerceEvent()`
* Bump Android sdk to 2.6.2
* Bump iOS sdk to 2.5.4

## 1.7.4
* Bump Android sdk to 2.6.1
* Bump iOS sdk to 2.5.2

## 1.7.3
* Bump Android sdk to 2.5.1
* Bump iOS sdk to 2.5.0
* AppInbox add customData property. Fix createdDate on iOS

## 1.7.2
* Bump Android sdk to 2.0.20
* Bump iOS sdk to 2.0.21
* Fix `Reteno.onRetenoNotificationClicked` not working on Android when push notification with link is clicked

## 1.7.1
* Add `Reteno.onUserNotificationAction` for listening on mobile push notifications actions

## 1.7.0
* Bump Android sdk to 2.0.12
* Bump iOS sdk to 2.0.11
* Update `initWith` method signature for Reteno initialization (Android only)
	- add device id provider parameter
	```dart
	await Reteno.initWith(
		accessKey: 'access_key',
		customDeviceId: () async {
			return await Amplitude.getInstance().getDeviceId();
		},
	);
	```
* Add `Reteno.appInbox` to get AppInbox messages

## 1.6.0
* Bump Android sdk to 2.0.11
* Added `initWith` method for Reteno initialization (Android only)

## 1.5.3
* Support AGP 8
* Bump Android sdk to 2.0.10
* Bump iOS sdk to 2.0.9

## 1.5.2
* Bump Android sdk to 2.0.7
* Bump iOS sdk to 2.0.6
* Add `Reteno.getRecommendations` to get recommendation
* Add `Reteno.logRecommendationsEvent` to log recommendation events

## 1.5.1
* Bump Android sdk to 2.0.2
* Bump iOS sdk to 2.0.2
* Add `Reteno.onInAppMessageStatusChanged` to get in-app message status changed events
* Add `Reteno.pauseInAppMessages` to pause or resume in-app messages

## 1.5.0
* Improve plugin stability when using with other plugins that use background isolate

## 1.4.2
* Fix PropertyAccessException in onDetachedFromEngine

## 1.4.1
### Dependencies
* Bump Android sdk to 1.7.1
* Added function for force updating push permission status on Android 13 and above

## 1.4.0
### Dependencies
* Bump Android sdk to 1.7.0
* Bump iOS sdk to 1.7.1

## 1.3.2
* Fix method channels initialization not properly working in pair with firebase messaging plugin
## 1.3.1
* Fix plugin not working when adding FirebaseMessaging.onBackgroundMessage handler due to spawning background isolate
* Update handling of config changes in android plugin

## 1.3.0
* Add `Reteno.onRetenoNotificationClicked` to get push data on clicked events

## 1.2.3
* Bump iOS sdk to 1.6.6

## 1.2.2
### Updates
 Supports push notifications with in-App messages
### Dependencies
* Bump Android sdk to 1.6.6
* Bump iOS sdk to 1.6.5
### Fixes
* Unable to use [sentry_flutter](https://pub.dev/packages/sentry_flutter) with **reteno_plugin** package ([#1](https://github.com/reteno-com/reteno-flutter/issues/1)). Native Reteno iOS SDK depends strictly on Sentry v8.8.0 so please use `sentry_flutter: 7.8.0` to satisfy this restriction.
## 1.2.1
* Update example with required proguard rules if you want to use `minifyEnable=true`
* Fix issue with unitialized `RetenoPushReceiver`

## 1.2.0

* Add `Reteno.logEvent` method to send custom events

## 1.1.0

* Add support for reteno android sdk 1.5.4
* Add support for reteno ios sdk 1.5.4
* Add `Reteno.setAnonymousUserAttributes` method to set anonymous user attributes
* Update Android `minSdkVersion` to 21

## 1.0.0

* Initial release of plugin
