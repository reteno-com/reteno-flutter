import 'dart:async';
import 'dart:io';

import 'package:reteno_plugin/src/extensions.dart';
import 'package:reteno_plugin/src/models/anonymous_user_attributes.dart';
import 'package:reteno_plugin/src/models/in_app_message_status.dart';
import 'package:reteno_plugin/src/models/lifecycle_tracking_options.dart';
import 'package:reteno_plugin/src/models/reteno_custom_event.dart';
import 'package:reteno_plugin/src/models/reteno_recommendation.dart';
import 'package:reteno_plugin/src/models/reteno_recommendation_event.dart';
import 'package:reteno_plugin/src/models/reteno_user.dart';
import 'package:reteno_plugin/src/reteno_plugin_platform_interface.dart';

import 'native_reteno_plugin.g.dart';

typedef OnNotificationCallback = void Function(Map<String?, Object?> payload);
typedef OnInAppMessageStatusChanged = void Function(
  InAppMessageStatus status,
);

class RetenoPigeonChannel extends RetenoPluginPlatform {
  static RetenoPigeonChannel? _instance;
  static RetenoPigeonChannel get instance => _instance ??= RetenoPigeonChannel._();

  factory RetenoPigeonChannel.instanceWithApi(RetenoHostApi api) {
    return RetenoPigeonChannel._(api: api);
  }

  late final RetenoHostApi _api;

  RetenoPigeonChannel._({
    RetenoHostApi? api,
  }) : _api = api ?? RetenoHostApi() {
    _setupListeners();
  }

  void _setupListeners() {
    RetenoFlutterApi.setUp(
      _RetenoFlutterApi(
        onNotificationCallback: (payload) {
          onRetenoNotificationReceived.add(Map<String, dynamic>.from(payload));
        },
        onRetenoNotificationClicked: (payload) {
          onRetenoNotificationClicked.add(Map<String, dynamic>.from(payload));
        },
        onInAppMessageStatusChangedCallback: (status) {
          onInAppMessageStatusChanged.add(status);
        },
      ),
    );
  }

  @override
  Future<void> initWith({
    required String accessKey,
    String? userId,
    bool isPausedInAppMessages = false,
    LifecycleTrackingOptions? lifecycleTrackingOptions,
  }) {
    return _api.initWith(
      accessKey: accessKey,
      userId: userId,
      isPausedInAppMessages: isPausedInAppMessages,
      lifecycleTrackingOptions: lifecycleTrackingOptions?.toNativeLifecycleTrackingOptions(),
    );
  }

  @override
  Future<bool> setUserAttributes(String externalUserId, RetenoUser? user) async {
    _api.setUserAttributes(externalUserId, user?.toNativeRetenoUser());
    return true;
  }

  @override
  Future<bool> setAnonymousUserAttributes(AnonymousUserAttributes anonymousUserAttributes) async {
    _api.setAnonymousUserAttributes(anonymousUserAttributes.toNativeAnonymousUserAttributes());
    return true;
  }

  @override
  Future<Map<dynamic, dynamic>?> getInitialNotification() async {
    final result = await _api.getInitialNotification();
    if (result != null) {
      return Map<String, dynamic>.from(result);
    }
    return null;
  }

  @override
  Future<bool> logEvent({
    required RetenoCustomEvent event,
  }) async {
    _api.logEvent(event.toCustomEvent());
    return true;
  }

  @override
  Future<bool> updatePushPermissionStatus() async {
    if (Platform.isAndroid) {
      _api.updatePushPermissionStatus();
    }
    return true;
  }

  @override
  Future<void> pauseInAppMessages(bool isPaused) {
    return _api.pauseInAppMessages(isPaused);
  }

  @override
  Future<List<RetenoRecommendation>> getRecommendations({
    required String recomenedationVariantId,
    required List<String> productIds,
    required String categoryId,
    List<RetenoRecomendationFilter>? filters,
    List<String?>? fields,
  }) async {
    final response = await _api.getRecommendations(
      recomVariantId: recomenedationVariantId,
      productIds: productIds,
      categoryId: categoryId,
      filters: filters?.map((e) => e.toNativeRecomFilter()).toList(),
      fields: fields,
    );
    return response.where((element) => element != null).map((e) => e!.toRetenoRecommendation()).toList();
  }

  @override
  Future<void> logRecommendationsEvent(RetenoRecomEvents events) {
    return _api.logRecommendationsEvent(events.toNativeRecomEvents());
  }
}

class _RetenoFlutterApi extends RetenoFlutterApi {
  _RetenoFlutterApi({
    required this.onNotificationCallback,
    required this.onRetenoNotificationClicked,
    required this.onInAppMessageStatusChangedCallback,
  });

  OnNotificationCallback onNotificationCallback;
  OnNotificationCallback onRetenoNotificationClicked;
  OnInAppMessageStatusChanged onInAppMessageStatusChangedCallback;

  @override
  void onNotificationClicked(Map<String?, Object?> payload) => onRetenoNotificationClicked(payload);

  @override
  void onNotificationReceived(Map<String?, Object?> payload) => onNotificationCallback(payload);

  @override
  void onInAppMessageStatusChanged(
    NativeInAppMessageStatus status,
    NativeInAppMessageAction? action,
    String? error,
  ) =>
      onInAppMessageStatusChangedCallback(status.toInAppMessageStatus(action, error));
}
