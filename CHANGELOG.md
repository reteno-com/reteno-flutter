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
