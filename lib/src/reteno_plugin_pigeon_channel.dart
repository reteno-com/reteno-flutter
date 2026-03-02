import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:reteno_plugin/src/extensions.dart';
import 'package:reteno_plugin/src/models/anonymous_user_attributes.dart';
import 'package:reteno_plugin/src/models/app_inbox_messages.dart';
import 'package:reteno_plugin/src/models/in_app_message_status.dart';
import 'package:reteno_plugin/src/models/lifecycle_tracking_options.dart';
import 'package:reteno_plugin/src/models/reteno_custom_event.dart';
import 'package:reteno_plugin/src/models/reteno_default_notification_channel_config.dart';
import 'package:reteno_plugin/src/models/reteno_device_token_handling_mode.dart';
import 'package:reteno_plugin/src/models/reteno_ecommerce_event.dart';
import 'package:reteno_plugin/src/models/reteno_in_app_custom_data.dart';
import 'package:reteno_plugin/src/models/reteno_recommendation.dart';
import 'package:reteno_plugin/src/models/reteno_recommendation_event.dart';
import 'package:reteno_plugin/src/models/reteno_user.dart';
import 'package:reteno_plugin/src/models/reteno_user_notification_action.dart';
import 'package:reteno_plugin/src/reteno_plugin_platform_interface.dart';

import 'native_reteno_plugin.g.dart';

typedef OnNotificationCallback = void Function(Map<String?, Object?> payload);
typedef OnInAppMessageStatusChanged = void Function(
  InAppMessageStatus status,
);
typedef OnMessagesCountChangedCallback = void Function(int count);
typedef OnNotificationActionHandler = void Function(
    RetenoUserNotificationAction action);
typedef OnInAppCustomDataReceived = void Function(RetenoInAppCustomData data);

class RetenoPigeonChannel extends RetenoPluginPlatform {
  static RetenoPigeonChannel? _instance;
  static RetenoPigeonChannel get instance =>
      _instance ??= RetenoPigeonChannel._();

  factory RetenoPigeonChannel.instanceWithApi(RetenoHostApi api) {
    return RetenoPigeonChannel._(api: api);
  }

  late final RetenoHostApi _api;
  late final AppInbox appInbox;

  static Future<String?> Function()? _getCustomDeviceId;

  RetenoPigeonChannel._({
    RetenoHostApi? api,
  }) : _api = api ?? RetenoHostApi() {
    appInbox = AppInbox(_api);
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
        onRetenoNotificationDeleted: (payload) {
          onRetenoNotificationDeleted.add(Map<String, dynamic>.from(payload));
        },
        onRetenoCustomNotificationReceived: (payload) {
          onRetenoCustomNotificationReceived
              .add(Map<String, dynamic>.from(payload));
        },
        onInAppMessageStatusChangedCallback: (status) {
          onInAppMessageStatusChanged.add(status);
        },
        onInAppCustomDataReceivedCallback: (data) {
          onRetenoInAppCustomDataReceived.add(data);
        },
        onMessagesCountChangedCallback: (count) {
          if (appInbox._messagesCountController != null) {
            appInbox._messagesCountController!.add(count);
          }
        },
        onNotificationActionCallback: (action) {
          onUserNotificationAction.add(action);
        },
      ),
    );
  }

  @override
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
    if (Platform.isAndroid &&
        deviceTokenHandlingMode != RetenoDeviceTokenHandlingMode.automatic) {
      developer.log(
        '[Reteno] `deviceTokenHandlingMode` is currently ignored on Android. '
        'Android uses native automatic token handling.',
        name: 'Reteno',
      );
    }
    if (Platform.isIOS && defaultNotificationChannelConfig != null) {
      developer.log(
        '[Reteno] `defaultNotificationChannelConfig` is Android-only and is ignored on iOS.',
        name: 'Reteno',
      );
    }

    _getCustomDeviceId = customDeviceId;
    return _api.initWith(
      accessKey: accessKey,
      isPausedInAppMessages: isPausedInAppMessages,
      isDebug: isDebug,
      lifecycleTrackingOptions:
          lifecycleTrackingOptions?.toNativeLifecycleTrackingOptions(),
      useCustomDeviceIdProvider: customDeviceId != null,
      deviceTokenHandlingMode:
          deviceTokenHandlingMode.toNativeDeviceTokenHandlingMode(),
      defaultNotificationChannelConfig: defaultNotificationChannelConfig
          ?.toNativeDefaultNotificationChannelConfig(),
    );
  }

  @override
  Future<bool> setUserAttributes(
      String externalUserId, RetenoUser? user) async {
    _api.setUserAttributes(externalUserId, user?.toNativeRetenoUser());
    return true;
  }

  @override
  Future<bool> setAnonymousUserAttributes(
      AnonymousUserAttributes anonymousUserAttributes) async {
    _api.setAnonymousUserAttributes(
        anonymousUserAttributes.toNativeAnonymousUserAttributes());
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
  Future<bool> requestPushPermission({bool provisional = false}) async {
    final granted = await _api.requestPushPermission(provisional: provisional);
    await updatePushPermissionStatus();
    return granted;
  }

  @override
  Future<bool> updatePushPermissionStatus() async {
    if (Platform.isAndroid) {
      _api.updatePushPermissionStatus();
    }
    return true;
  }

  @override
  Future<List<String>> diagnose() {
    return _api.diagnose();
  }

  @override
  Future<void> pauseInAppMessages(bool isPaused) {
    return _api.pauseInAppMessages(isPaused);
  }

  @override
  Future<List<RetenoRecommendation>> getRecommendations({
    required String recomenedationVariantId,
    required List<String> productIds,
    String? categoryId,
    List<RetenoRecomendationFilter>? filters,
    List<String>? fields,
  }) async {
    final response = await _api.getRecommendations(
      recomVariantId: recomenedationVariantId,
      productIds: productIds,
      categoryId: categoryId,
      filters: filters?.map((e) => e.toNativeRecomFilter()).toList(),
      fields: fields,
    );
    return response.map((e) => e.toRetenoRecommendation()).toList();
  }

  @override
  Future<Map<String, dynamic>> getRecommendationsJson(
      {required String recomenedationVariantId,
      required List<String> productIds,
      String? categoryId,
      List<RetenoRecomendationFilter>? filters,
      List<String>? fields}) {
    return _api.getRecommendationsJson(
      recomVariantId: recomenedationVariantId,
      productIds: productIds,
      categoryId: categoryId,
      filters: filters?.map((e) => e.toNativeRecomFilter()).toList(),
      fields: fields,
    );
  }

  @override
  Future<void> logRecommendationsEvent(RetenoRecomEvents events) {
    return _api.logRecommendationsEvent(events.toNativeRecomEvents());
  }

  @override
  Future<void> logEcommerceEvent(RetenoEcommerceEvent event) {
    return switch (event) {
      RetenoEcommerceProductViewed(
        product: RetenoEcommerceProduct product,
        currency: String? currency,
      ) =>
        _api.logEcommerceProductViewed(
          product.toNativeEcommerceProduct(),
          currency,
        ),
      RetenoEcommerceProductCategoryViewed(
        category: RetenoEcommerceCategory category
      ) =>
        _api.logEcommerceProductCategoryViewed(
          category.toNativeEcommerceCategory(),
        ),
      RetenoEcommerceProductAddedToWishlist(
        product: RetenoEcommerceProduct product,
        currency: String? currency,
      ) =>
        _api.logEcommerceProductAddedToWishlist(
          product.toNativeEcommerceProduct(),
          currency,
        ),
      RetenoEcommerceCartUpdated(
        cartId: String cartId,
        products: List<RetenoEcommerceProductInCart> products,
        currency: String? currency,
      ) =>
        _api.logEcommerceCartUpdated(
          cartId,
          products.map((e) => e.toNativeEcommerceProductInCart()).toList(),
          currency,
        ),
      RetenoEcommerceOrderCreated(
        order: RetenoEcommerceOrder order,
        currency: String? currency,
      ) =>
        _api.logEcommerceOrderCreated(
          order.toNativeEcommerceOrder(),
          currency,
        ),
      RetenoEcommerceOrderUpdated(
        order: RetenoEcommerceOrder order,
        currency: String? currency,
      ) =>
        _api.logEcommerceOrderUpdated(
          order.toNativeEcommerceOrder(),
          currency,
        ),
      RetenoEcommerceOrderDelivered(
        externalOrderId: String externalOrderId,
      ) =>
        _api.logEcommerceOrderDelivered(externalOrderId),
      RetenoEcommerceOrderCancelled(
        externalOrderId: String externalOrderId,
      ) =>
        _api.logEcommerceOrderCancelled(externalOrderId),
      RetenoEcommerceSearchRequest(
        query: String query,
        isFound: bool? isFound,
      ) =>
        _api.logEcommerceSearchRequest(query, isFound),
    };
  }

  static Future<String?>? _getCustomDeviceIdInternal() {
    return _getCustomDeviceId?.call();
  }
}

class _RetenoFlutterApi extends RetenoFlutterApi {
  _RetenoFlutterApi({
    required this.onNotificationCallback,
    required this.onRetenoNotificationClicked,
    required this.onRetenoNotificationDeleted,
    required this.onRetenoCustomNotificationReceived,
    required this.onInAppMessageStatusChangedCallback,
    required this.onInAppCustomDataReceivedCallback,
    required this.onMessagesCountChangedCallback,
    required this.onNotificationActionCallback,
  });

  OnNotificationCallback onNotificationCallback;
  OnNotificationCallback onRetenoNotificationClicked;
  OnNotificationCallback onRetenoNotificationDeleted;
  OnNotificationCallback onRetenoCustomNotificationReceived;
  OnInAppMessageStatusChanged onInAppMessageStatusChangedCallback;
  OnInAppCustomDataReceived onInAppCustomDataReceivedCallback;
  OnMessagesCountChangedCallback onMessagesCountChangedCallback;
  OnNotificationActionHandler onNotificationActionCallback;

  @override
  void onNotificationClicked(Map<String?, Object?> payload) =>
      onRetenoNotificationClicked(payload);

  @override
  void onNotificationDeleted(Map<String?, Object?> payload) =>
      onRetenoNotificationDeleted(payload);

  @override
  void onCustomNotificationReceived(Map<String?, Object?> payload) =>
      onRetenoCustomNotificationReceived(payload);

  @override
  void onNotificationReceived(Map<String?, Object?> payload) =>
      onNotificationCallback(payload);

  @override
  void onInAppCustomDataReceived(NativeInAppCustomData payload) {
    onInAppCustomDataReceivedCallback(
      RetenoInAppCustomData(
        url: payload.url,
        source: payload.source,
        inAppId: payload.inAppId,
        data: Map<String, String>.from(
          payload.data.map(
            (key, value) => MapEntry(
              key ?? '',
              value ?? '',
            ),
          ),
        ),
      ),
    );
  }

  @override
  void onNotificationActionHandler(NativeUserNotificationAction action) {
    onNotificationActionCallback(action.toUserNotificationAction());
  }

  @override
  void onInAppMessageStatusChanged(
    NativeInAppMessageStatus status,
    NativeInAppMessageAction? action,
    String? error,
  ) =>
      onInAppMessageStatusChangedCallback(
          status.toInAppMessageStatus(action, error));

  @override
  void onMessagesCountChanged(int count) {
    onMessagesCountChangedCallback(count);
  }

  @override
  Future<String?> getDeviceId() async {
    return await RetenoPigeonChannel._getCustomDeviceIdInternal();
  }
}

class AppInbox {
  final RetenoHostApi _api;

  AppInbox(this._api);
  StreamController<int>? _messagesCountController;

  // Obtain AppInbox messages count and observing the to value change.
  Stream<int> get onMessagesCountChanged {
    if (_messagesCountController == null) {
      _messagesCountController = StreamController.broadcast();
      _api.subscribeOnMessagesCountChanged();
    }
    return _messagesCountController!.stream;
  }

  /// Get AppInbox messages.
  /// - `page` - page - order number of requested page. If null will be returned all messages.
  /// - `pageSize` - pageSize - number of messages in one page. If null will be returned all messages.
  Future<AppInboxMessages> getAppInboxMessages(
      {int? page, int? pageSize}) async {
    final nativeMessages =
        await _api.getAppInboxMessages(page: page, pageSize: pageSize);
    return nativeMessages.toAppInboxMessages();
  }

  /// Obtain AppInbox messages count once.
  Future<int> getAppInboxMessagesCount() {
    return _api.getAppInboxMessagesCount();
  }

  /// Change inbox message status on OPENED
  /// - `messageId` - message id
  Future<void> markAsOpened(String messageId) {
    return _api.markAsOpened(messageId);
  }

  /// Change all inbox messages status on OPENED
  Future<void> markAllMessagesAsOpened() {
    return _api.markAllMessagesAsOpened();
  }
}
