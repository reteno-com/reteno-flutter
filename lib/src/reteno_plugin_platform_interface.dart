import 'dart:async';

import 'package:reteno_plugin/src/models/anonymous_user_attributes.dart';
import 'package:reteno_plugin/src/models/in_app_message_status.dart';
import 'package:reteno_plugin/src/models/lifecycle_tracking_options.dart';
import 'package:reteno_plugin/src/models/reteno_custom_event.dart';
import 'package:reteno_plugin/src/models/reteno_ecommerce_event.dart';
import 'package:reteno_plugin/src/models/reteno_recommendation.dart';
import 'package:reteno_plugin/src/models/reteno_recommendation_event.dart';
import 'package:reteno_plugin/src/models/reteno_user.dart';
import 'package:reteno_plugin/src/models/reteno_user_notification_action.dart';

abstract class RetenoPluginPlatform {
  Future<void> initWith({
    required String accessKey,
    bool isPausedInAppMessages = false,
    bool isDebug = false,
    LifecycleTrackingOptions? lifecycleTrackingOptions,
    Future<String?> Function()? customDeviceId,
  }) {
    throw UnimplementedError('initWith() has not been implemented.');
  }

  Future<bool> setUserAttributes(String externalUserId, RetenoUser? user) {
    throw UnimplementedError('setUserAtrributes() has not been implemented.');
  }

  Future<bool> setAnonymousUserAttributes(AnonymousUserAttributes anonymousUserAttributes) {
    throw UnimplementedError('setAnonymousUserAttributes() has not been implemented.');
  }

  StreamController<Map<String, dynamic>> onRetenoNotificationReceived =
      StreamController<Map<String, dynamic>>.broadcast();

  StreamController<Map<String, dynamic>> onRetenoNotificationClicked =
      StreamController<Map<String, dynamic>>.broadcast();

  StreamController<InAppMessageStatus> onInAppMessageStatusChanged = StreamController<InAppMessageStatus>.broadcast();

  StreamController<RetenoUserNotificationAction> onUserNotificationAction =
      StreamController<RetenoUserNotificationAction>.broadcast();

  Future<Map<dynamic, dynamic>?> getInitialNotification() {
    throw UnimplementedError('getInitialNotification() has not been implemented.');
  }

  Future<bool> logEvent({required RetenoCustomEvent event}) {
    throw UnimplementedError('logEvent() has not been implemented.');
  }

  Future<bool> updatePushPermissionStatus() {
    throw UnimplementedError('updatePushPermissionStatus() has not been implemented.');
  }

  Future<void> pauseInAppMessages(bool isPaused) {
    throw UnimplementedError('pauseInAppMessages() has not been implemented.');
  }

  Future<List<RetenoRecommendation>> getRecommendations({
    required String recomenedationVariantId,
    required List<String> productIds,
    String? categoryId,
    List<RetenoRecomendationFilter>? filters,
    List<String>? fields,
  }) {
    throw UnimplementedError('getRecommendations() has not been implemented.');
  }

  Future<void> logRecommendationsEvent(RetenoRecomEvents events) {
    throw UnimplementedError('logRecommendationsEvent() has not been implemented.');
  }

  Future<void> logEcommerceEvent(RetenoEcommerceEvent event) {
    throw UnimplementedError('logEcommerceEvent() has not been implemented.');
  }
}
