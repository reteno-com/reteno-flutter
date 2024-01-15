import 'package:reteno_plugin/anonymous_user_attributes.dart';
import 'package:reteno_plugin/reteno_custom_event.dart';
import 'package:reteno_plugin/reteno_user.dart';

import 'reteno_plugin_platform_interface.dart';

class Reteno {
  Future<bool> setUserAttributes({
    required String userExternalId,
    RetenoUser? user,
  }) {
    return RetenoPluginPlatform.instance
        .setUserAttributes(userExternalId, user);
  }

  Future<bool> setAnomymousUserAttributes({
    required AnonymousUserAttributes anonymousUserAttributes,
  }) {
    return RetenoPluginPlatform.instance
        .setAnonymousUserAttributes(anonymousUserAttributes);
  }

  /// A static getter that provides a [Stream] of notifications received when application is in foreground.
  ///
  /// This [Stream] emits [Map] objects containing notification data in the form of
  /// key-value pairs, where keys are strings and values are dynamic types.
  /// You can use this stream to listen for notifications as they are received
  /// by the Reteno plugin and react to them in your Flutter application.
  ///
  /// Example usage:
  /// ```dart
  /// RetenoPlugin.onRetenoNotificationReceived.listen((notification) {
  ///   // Handle the received notification here
  ///   print("Received notification: $notification");
  /// });
  /// ```
  static Stream<Map<String, dynamic>> get onRetenoNotificationReceived =>
      RetenoPluginPlatform.instance.onRetenoNotificationReceived.stream;

  /// A static getter that provides a [Stream] of notifications clicked by the user
  /// in foreground and background states.
  ///
  /// This [Stream] emits [Map] objects containing notification data in the form of
  /// key-value pairs, where keys are strings and values are dynamic types.
  /// You can use this stream to listen for notifications that the user has clicked
  /// on in your Flutter application and take appropriate actions based on the clicked
  /// notification.
  ///
  /// Example usage:
  /// ```dart
  /// RetenoPlugin.onRetenoNotificationClicked.listen((notification) {
  ///   // Handle the clicked notification here
  ///   print("Clicked notification: $notification");
  /// });
  /// ```
  static Stream<Map<String, dynamic>> get onRetenoNotificationClicked =>
      RetenoPluginPlatform.instance.onRetenoNotificationClicked.stream;

  /// Retrieves the initial notification when app is opened from terminated state by notification.
  ///
  /// This method returns a [Future] that resolves to a dynamic value. The value
  /// may be a [Map] containing notification data in the form of key-value pairs,
  /// where keys are strings and values are dynamic types, or `null` if there
  /// was no initial notification.
  ///
  /// You can use this method to check if your Flutter application was launched
  /// as a result of a user tapping a notification and retrieve the associated
  /// notification data.
  ///
  /// Example usage:
  /// ```dart
  /// Future<void> handleInitialNotification() async {
  ///   final initialNotification = await RetenoPlugin.getInitialNotification();
  ///   if (initialNotification != null) {
  ///     // Handle the initial notification here
  ///     print("Initial notification: $initialNotification");
  ///   } else {
  ///     // The app was launched without a notification
  ///     print("No initial notification.");
  ///   }
  /// }
  /// ```
  /// Returns a [Future] that resolves to a dynamic value representing the
  /// initial notification or `null` if there was no initial notification.
  Future<dynamic> getInitialNotification() {
    return RetenoPluginPlatform.instance.getInitialNotification();
  }

  Future<bool> logEvent({
    required RetenoCustomEvent event,
  }) {
    return RetenoPluginPlatform.instance.logEvent(event: event);
  }

  /// Updates status of POST_NOTIFICATIONS permission and pushes it to backend if status was changed.
  /// 
  /// For example you can call this function after acquiring result from runtime permission on Android 13 and above
  Future<bool> updatePushPermissionStatus() {
    return RetenoPluginPlatform.instance.updatePushPermissionStatus();
  }
}
