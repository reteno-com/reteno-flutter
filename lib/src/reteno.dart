import 'package:reteno_plugin/src/reteno_plugin_pigeon_channel.dart';
import 'package:reteno_plugin/src/models/anonymous_user_attributes.dart';
import 'package:reteno_plugin/src/models/in_app_message_status.dart';
import 'package:reteno_plugin/src/models/lifecycle_tracking_options.dart';
import 'package:reteno_plugin/src/models/reteno_custom_event.dart';
import 'package:reteno_plugin/src/models/reteno_custom_event_parameter.dart';
import 'package:reteno_plugin/src/models/reteno_default_notification_channel_config.dart';
import 'package:reteno_plugin/src/models/reteno_device_token_handling_mode.dart';
import 'package:reteno_plugin/src/models/reteno_ecommerce_event.dart';
import 'package:reteno_plugin/src/models/reteno_in_app_custom_data.dart';
import 'package:reteno_plugin/src/models/reteno_init_options.dart';
import 'package:reteno_plugin/src/models/reteno_recommendation.dart';
import 'package:reteno_plugin/src/models/reteno_recommendation_event.dart';
import 'package:reteno_plugin/src/models/reteno_user.dart';
import 'package:reteno_plugin/src/models/reteno_user_notification_action.dart';

import 'reteno_plugin_platform_interface.dart';

class Reteno {
  static final RetenoPluginPlatform _platform = RetenoPigeonChannel.instance;

  /// Reteno `AppInbox` instance.
  static AppInbox get appInbox => RetenoPigeonChannel.instance.appInbox;

  /// Canonical initialization entrypoint.
  Future<void> initialize({
    required String accessKey,
    RetenoInitOptions options = const RetenoInitOptions(),
    Future<String?> Function()? customDeviceId,
  }) {
    return _platform.initWith(
      accessKey: accessKey,
      isPausedInAppMessages: options.isPausedInAppMessages,
      lifecycleTrackingOptions: options.lifecycleTrackingOptions,
      customDeviceId: customDeviceId,
      isDebug: options.isDebug,
      deviceTokenHandlingMode: options.deviceTokenHandlingMode,
      defaultNotificationChannelConfig:
          options.defaultNotificationChannelConfig,
    );
  }

  /// Backward-compatible alias for [initialize].
  Future<void> initWith({
    required String accessKey,
    bool isPausedInAppMessages = false,
    bool isDebug = false,
    LifecycleTrackingOptions? lifecycleTrackingOptions,
    Future<String?> Function()? customDeviceId,
    RetenoDeviceTokenHandlingMode deviceTokenHandlingMode =
        RetenoDeviceTokenHandlingMode.automatic,
    RetenoDefaultNotificationChannelConfig? defaultNotificationChannelConfig,
  }) {
    return initialize(
      accessKey: accessKey,
      customDeviceId: customDeviceId,
      options: RetenoInitOptions(
        isPausedInAppMessages: isPausedInAppMessages,
        isDebug: isDebug,
        lifecycleTrackingOptions: lifecycleTrackingOptions,
        deviceTokenHandlingMode: deviceTokenHandlingMode,
        defaultNotificationChannelConfig: defaultNotificationChannelConfig,
      ),
    );
  }

  /// Update User attributes
  /// - Parameter `externalUserId`: Id for identify user in a system
  /// - RetenoUser
  ///   - Parameter `userAttributes`: user specific attributes in format `UserAttributes` (firstName, phone, email, etc.) (optional)
  ///   - Parameter `subscriptionKeys`: list of subscription categories keys, can be empty
  ///   - Parameter `groupNamesInclude`: list of group ID to add a contact to, can be empty
  ///   - Parameter `groupNamesExclude`: list of group ID to remove a contact from, can be empty
  Future<bool> setUserAttributes({
    required String userExternalId,
    RetenoUser? user,
  }) {
    return _platform.setUserAttributes(userExternalId, user);
  }

  /// Update Anonymous User attributes
  /// - Parameter `userAttributes`: user specific attributes in format `AnonymousUserAttributes` (firstName, address, etc.)
  /// - Parameter `subscriptionKeys`: list of subscription categories keys, can be empty
  /// - Parameter `groupNamesInclude`: list of group ID to add a contact to, can be empty
  /// - Parameter `groupNamesExclude`: list of group ID to remove a contact from, can be empty
  Future<bool> setAnomymousUserAttributes({
    required AnonymousUserAttributes anonymousUserAttributes,
  }) {
    return _platform.setAnonymousUserAttributes(anonymousUserAttributes);
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
  /// Reteno.onRetenoNotificationReceived.listen((notification) {
  ///   // Handle the received notification here
  ///   print("Received notification: $notification");
  /// });
  /// ```
  static Stream<Map<String, dynamic>> get onRetenoNotificationReceived =>
      _platform.onRetenoNotificationReceived.stream;

  /// Cross-platform core stream alias for push received events.
  static Stream<Map<String, dynamic>> get onCorePushReceived =>
      onRetenoNotificationReceived;

  /// A static getter that provides a [Stream] of user notification actions.
  /// This [Stream] emits [RetenoUserNotificationAction] object
  /// RetenoUserNotificationAction
  /// - Parameter `actionId`: A unique identifier for the button action.
  /// - Parameter `customData`: key-value pairs of additional parameters associated with the button
  /// - Parameter `link`: An URL or a deeplink that opens when the notification is selected
  ///
  /// Example usage:
  /// ```dart
  /// Reteno.onUserNotificationAction.listen((action) {
  ///   // Handle the user notification action here
  ///   print("User notification action: $action");
  /// });
  /// ```
  static Stream<RetenoUserNotificationAction> get onUserNotificationAction =>
      _platform.onUserNotificationAction.stream;

  /// Cross-platform core stream alias for push action events.
  static Stream<RetenoUserNotificationAction> get onCorePushAction =>
      onUserNotificationAction;

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
  /// Reteno.onRetenoNotificationClicked.listen((notification) {
  ///   // Handle the clicked notification here
  ///   print("Clicked notification: $notification");
  /// });
  /// ```
  static Stream<Map<String, dynamic>> get onRetenoNotificationClicked =>
      _platform.onRetenoNotificationClicked.stream;

  /// Cross-platform core stream alias for push clicked events.
  static Stream<Map<String, dynamic>> get onCorePushClicked =>
      onRetenoNotificationClicked;

  /// Platform-specific stream for push dismissed (currently Android SDK event source).
  static Stream<Map<String, dynamic>> get onRetenoNotificationDeleted =>
      _platform.onRetenoNotificationDeleted.stream;

  /// Platform-specific stream for custom push payload callbacks (currently Android SDK event source).
  static Stream<Map<String, dynamic>> get onRetenoCustomNotificationReceived =>
      _platform.onRetenoCustomNotificationReceived.stream;

  /// Platform-specific stream for in-app custom data callbacks (currently Android SDK event source).
  static Stream<RetenoInAppCustomData> get onRetenoInAppCustomDataReceived =>
      _platform.onRetenoInAppCustomDataReceived.stream;

  /// A static getter that provides a [Stream] of in-app message status changes.
  /// You can detect In-App presenting status where needed.
  /// `InAppShouldBeDisplayed` - called when the in-app should be displayed
  /// `InAppIsDisplayed` - called when the in-app is displayed
  /// `InAppShouldBeClosed` - called when the in-app should be closed
  /// `InAppIsClosed` - called when the in-app is closed
  /// `InAppReceivedError` - called when the in-app can't be shown for some reason
  ///
  /// Example usage:
  ///  ```dart
  /// Reteno.onInAppMessageStatusChanged.listen((status) {
  ///     switch (status) {
  ///       case InAppShouldBeDisplayed():
  ///         print('In-app should be displayed');
  ///       case InAppIsDisplayed():
  ///         print('In-app is displayed');
  ///       case InAppShouldBeClosed(:final action):
  ///         print('In-app should be closed $action');
  ///       case InAppIsClosed(:final action):
  ///         print('In-app is closed $action');
  ///       case InAppReceivedError(:final errorMessage):
  ///         print('In-app error: $errorMessage');
  ///     }
  ///   });
  /// ```
  ///
  static Stream<InAppMessageStatus> get onInAppMessageStatusChanged =>
      _platform.onInAppMessageStatusChanged.stream;

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
    return _platform.getInitialNotification();
  }

  /// Track custom events
  ///
  /// `eventTypeKey` Event type ID
  /// `dateOccurred` Time when event occurred
  /// `parameters` List of event parameters as array of "key" - "value" pairs. Parameter keys are arbitrary. Used in campaigns and for dynamic content creation in messages
  /// `forcePush` indicates if event should be send immediately or in the next scheduled batch. iOS only feature
  ///
  /// Example usage:
  /// ```dart
  /// final event = RetenoCustomEvent(
  ///   eventTypeKey: 'contact_form',
  ///   dateOccurred: DateTime.now(),
  ///   parameters: [
  ///     RetenoCustomEventParameter('name', 'John Doe'),
  ///   ],
  ///   forcePush: true,
  /// );
  /// await Reteno.logEvent(event: event);
  /// ```
  ///
  Future<bool> logEvent({
    required RetenoCustomEvent event,
  }) {
    return _platform.logEvent(event: event);
  }

  /// Convenience helper to log event with JSON parameters map.
  Future<bool> logEventJson({
    required String eventTypeKey,
    required Map<String, String> jsonParameters,
    DateTime? dateOccurred,
    bool forcePush = false,
  }) {
    return logEvent(
      event: RetenoCustomEvent(
        eventTypeKey: eventTypeKey,
        dateOccurred: dateOccurred ?? DateTime.now(),
        forcePush: forcePush,
        parameters: jsonParameters.entries
            .map((entry) => RetenoCustomEventParameter(entry.key, entry.value))
            .toList(),
      ),
    );
  }

  /// Requests push permission on iOS and Android 13+ and syncs status to backend.
  /// - Parameter `provisional`: iOS provisional authorization (iOS 12+).
  Future<bool> requestPushPermission({bool provisional = false}) {
    return _platform.requestPushPermission(provisional: provisional);
  }

  /// Updates status of POST_NOTIFICATIONS permission and pushes it to backend if status was changed.
  ///
  /// For example you can call this function after acquiring result from runtime permission on Android 13 and above
  Future<bool> updatePushPermissionStatus() {
    return _platform.updatePushPermissionStatus();
  }

  /// Returns integration diagnostics codes from native SDK/plugin.
  Future<List<String>> diagnose() {
    return _platform.diagnose();
  }

  /// Pause or resume in-app messages
  /// - Parameter `isPaused`: true - pause, false - resume
  Future<void> pauseInAppMessages(bool isPaused) {
    return _platform.pauseInAppMessages(isPaused);
  }

  /// Get product recommendations
  /// - Parameter `recomenedationVariantId`: recommendation variant ID
  /// - Parameter `productIds`: product IDs for product-based algorithms
  /// - Parameter `categoryId`: product category ID for category-based algorithms
  /// - Parameter `filters`: list of `RetenoRecomendationFilter` filters - additional algorithm filters array
  ///  - Note: filters not supported on Android SDK yet
  /// - Parameter `fields`: response model fields keys
  ///
  /// Example usage:
  /// ```dart
  /// final recommendations = await Reteno.getRecommendations(
  ///   recomenedationVariantId: 'r1107v1482',
  ///   productIds: ['240-LV09', '24-WG080'],
  ///   categoryId: 'Default Category/Training/Video Download',
  ///   filters: [RetenoRecomendationFilter(name: 'filter_name', values: ['filter_value'])],
  ///   fields: ['productId', 'name', 'descr', 'imageUrl', 'price'],
  /// );
  /// ```
  ///
  Future<List<RetenoRecommendation>> getRecommendations({
    required String recomenedationVariantId,
    required List<String> productIds,
    String? categoryId,
    List<RetenoRecomendationFilter>? filters,
    List<String>? fields,
  }) {
    return _platform.getRecommendations(
      recomenedationVariantId: recomenedationVariantId,
      productIds: productIds,
      categoryId: categoryId,
      filters: filters,
      fields: fields,
    );
  }

  /// Get recommendations as JSON
  /// - Parameter `recomenedationVariantId`: recommendation variant ID
  /// - Parameter `productIds`: product IDs for product-based algorithms
  /// - Parameter `categoryId`: product category ID for category-based algorithms
  /// - Parameter `filters`: list of `RetenoRecomendationFilter` filters - additional algorithm filters array
  ///  - Note: filters not supported on Android SDK yet
  /// - Parameter `fields`: response model fields keys
  ///
  Future<Map<String, dynamic>> getRecommendationsJson(
      {required String recomenedationVariantId,
      required List<String> productIds,
      String? categoryId,
      List<RetenoRecomendationFilter>? filters,
      List<String>? fields}) {
    return _platform.getRecommendationsJson(
      recomenedationVariantId: recomenedationVariantId,
      productIds: productIds,
      categoryId: categoryId,
      filters: filters,
      fields: fields,
    );
  }

  /// Log recommendations events
  /// `RetenoRecomEvents` - recommendation event to be logged
  ///  - `recomVariantId` - recommendation variant ID
  /// - `events` - list of `RetenoRecomEvent` recommendation events
  ///     - `productId` - product ID
  ///     - `eventType` - event type
  ///         - `impression` - events describing that a specific product recommendation was shown to a user
  ///         - `click` - events describing that a user clicked a specific product recommendation
  ///     - `dateOccurred` - time when event occurred
  /// Example usage:
  /// ```dart
  /// final event = RetenoRecomEvent(
  ///   eventType: RetenoRecomEventType.impression,
  ///   dateOccurred: DateTime.now(),
  ///   productId: 'product_id',
  /// );
  ///
  /// final events = RetenoRecomEvents(
  ///   recomVariantId: 'recom_variant_id',
  ///   events: [event],
  /// );
  ///
  /// await Reteno.logRecommendationsEvent(events);
  /// ```
  Future<void> logRecommendationsEvent(RetenoRecomEvents events) {
    return _platform.logRecommendationsEvent(events);
  }

  /// Reteno's e-commerce activity tracking helps to learn about the customer journey and use this data in your analytics.
  /// The list of supported events:
  /// supported events:
  /// - `RetenoEcommerceProductViewed`
  /// - `RetenoEcommerceProductCategoryViewed`
  /// - `RetenoEcommerceProductAddedToWishlist`
  /// - `RetenoEcommerceCartUpdated`
  /// - `RetenoEcommerceOrderCreated`
  /// - `RetenoEcommerceOrderUpdated`
  /// - `RetenoEcommerceOrderDelivered`
  /// - `RetenoEcommerceOrderCancelled`
  /// - `RetenoEcommerceSearchRequest`
  Future<void> logEcommerceEvent(RetenoEcommerceEvent event) {
    return _platform.logEcommerceEvent(event);
  }
}
