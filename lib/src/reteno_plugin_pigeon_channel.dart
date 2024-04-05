import 'dart:async';
import 'dart:io';

import 'package:reteno_plugin/src/extensions.dart';
import 'package:reteno_plugin/src/models/anonymous_user_attributes.dart';
import 'package:reteno_plugin/src/models/in_app_message_status.dart';
import 'package:reteno_plugin/src/models/reteno_custom_event.dart';
import 'package:reteno_plugin/src/models/reteno_user.dart';
import 'package:reteno_plugin/src/reteno_plugin_platform_interface.dart';

import 'native_reteno_plugin.g.dart';

typedef OnNotificationCallback = void Function(Map<String?, Object?> payload);
typedef OnInAppMessageStatusChanged = void Function(
  InAppMessageStatus status,
);

class RetenoPigeonChannel extends RetenoPluginPlatform {
  static RetenoPigeonChannel? _instance;
  static RetenoPigeonChannel get instance =>
      _instance ??= RetenoPigeonChannel._();

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
    RetenoFlutterApi.setup(
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
  void onNotificationClicked(Map<String?, Object?> payload) =>
      onRetenoNotificationClicked(payload);

  @override
  void onNotificationReceived(Map<String?, Object?> payload) =>
      onNotificationCallback(payload);

  @override
  void onInAppMessageStatusChanged(
    NativeInAppMessageStatus status,
    NativeInAppMessageAction? action,
    String? error,
  ) =>
      onInAppMessageStatusChangedCallback(
          status.toInAppMessageStatus(action, error));
}

extension on NativeInAppMessageStatus {
  InAppMessageStatus toInAppMessageStatus(
      NativeInAppMessageAction? action, String? error) {
    switch (this) {
      case NativeInAppMessageStatus.inAppShouldBeDisplayed:
        return InAppShouldBeDisplayed();
      case NativeInAppMessageStatus.inAppIsDisplayed:
        return InAppIsDisplayed();
      case NativeInAppMessageStatus.inAppShouldBeClosed:
        return InAppShouldBeClosed(
          action: action!.toInAppMessageAction(),
        );
      case NativeInAppMessageStatus.inAppIsClosed:
        return InAppIsClosed(
          action: action!.toInAppMessageAction(),
        );
      case NativeInAppMessageStatus.inAppReceivedError:
        return InAppReceivedError(
          errorMessage: error!,
        );
    }
  }
}

extension on NativeInAppMessageAction {
  InAppMessageAction toInAppMessageAction() {
    return InAppMessageAction(
      isCloseButtonClicked: isCloseButtonClicked,
      isButtonClicked: isButtonClicked,
      isOpenUrlClicked: isOpenUrlClicked,
    );
  }
}
