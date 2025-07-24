import 'package:reteno_plugin/reteno.dart';
import 'package:reteno_plugin/src/reteno_plugin_pigeon_channel.dart';

import 'reteno_plugin_platform_interface.dart';

class Reteno {
  static final RetenoPluginPlatform _platform = RetenoPigeonChannel.instance;

  /// Reteno `AppInbox` instance.
  static AppInbox get appInbox => RetenoPigeonChannel.instance.appInbox;

  /// NOTE: Android SDK only
  /// Method for finishing delayed initialization of RetenoSDK,
  /// - Parameter `accessKey`: Reteno Access Key
  /// - Parameter `isPausedInAppMessages`: indicates paused/resumed state for in-app messages
  ///   Reteno SDK will wait till id is going to be non-null then will initialize itself
  /// - Parameter `lifecycleTrackingOptions`: behavior of automatic app lifecycle event tracking
  /// - Parameter `customDeviceId`: custom device id provider
  ///   Reteno SDK will wait till id is going to be non-null
  /// example:
  /// ```dart
  /// await Reteno.initWith(
  ///   accessKey: 'access_key',
  ///   isPausedInAppMessages: true,
  ///   lifecycleTrackingOptions: LifecycleTrackingOptions(
  ///     appLifecycleEnabled: true,
  ///     pushSubscriptionEnabled: true,
  ///     sessionEventsEnabled: true,
  ///   ),
  ///   customDeviceId: () async {
  ///     return await Amplitude.getInstance().getDeviceId();
  ///   },
  /// );
  /// ```

  Future<void> initWith({
    required String accessKey,
    bool isPausedInAppMessages = false,
    LifecycleTrackingOptions? lifecycleTrackingOptions,
    Future<String?> Function()? customDeviceId,
  }) {
    return _platform.initWith(
      accessKey: accessKey,
      isPausedInAppMessages: isPausedInAppMessages,
      lifecycleTrackingOptions: lifecycleTrackingOptions,
      customDeviceId: customDeviceId,
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
  static Stream<Map<String, dynamic>> get onRetenoNotificationReceived => _platform.onRetenoNotificationReceived.stream;

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
  static Stream<RetenoUserNotificationAction> get onUserNotificationAction => _platform.onUserNotificationAction.stream;

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
  static Stream<Map<String, dynamic>> get onRetenoNotificationClicked => _platform.onRetenoNotificationClicked.stream;

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
  static Stream<InAppMessageStatus> get onInAppMessageStatusChanged => _platform.onInAppMessageStatusChanged.stream;

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

  /// Updates status of POST_NOTIFICATIONS permission and pushes it to backend if status was changed.
  ///
  /// For example you can call this function after acquiring result from runtime permission on Android 13 and above
  Future<bool> updatePushPermissionStatus() {
    return _platform.updatePushPermissionStatus();
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
    required String categoryId,
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
