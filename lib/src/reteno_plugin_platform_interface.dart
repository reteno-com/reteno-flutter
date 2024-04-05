import 'dart:async';

import 'package:reteno_plugin/src/models/anonymous_user_attributes.dart';
import 'package:reteno_plugin/src/models/in_app_message_status.dart';
import 'package:reteno_plugin/src/models/reteno_custom_event.dart';
import 'package:reteno_plugin/src/models/reteno_user.dart';

abstract class RetenoPluginPlatform {
  Future<bool> setUserAttributes(String externalUserId, RetenoUser? user) {
    throw UnimplementedError('setUserAtrributes() has not been implemented.');
  }

  Future<bool> setAnonymousUserAttributes(
      AnonymousUserAttributes anonymousUserAttributes) {
    throw UnimplementedError(
        'setAnonymousUserAttributes() has not been implemented.');
  }

  StreamController<Map<String, dynamic>> onRetenoNotificationReceived =
      StreamController<Map<String, dynamic>>.broadcast();

  StreamController<Map<String, dynamic>> onRetenoNotificationClicked =
      StreamController<Map<String, dynamic>>.broadcast();

  StreamController<InAppMessageStatus> onInAppMessageStatusChanged =
      StreamController<InAppMessageStatus>.broadcast();

  Future<Map<dynamic, dynamic>?> getInitialNotification() {
    throw UnimplementedError(
        'getInitialNotification() has not been implemented.');
  }

  Future<bool> logEvent({required RetenoCustomEvent event}) {
    throw UnimplementedError('logEvent() has not been implemented.');
  }

  Future<bool> updatePushPermissionStatus() {
    throw UnimplementedError(
        'updatePushPermissionStatus() has not been implemented.');
  }

  Future<void> pauseInAppMessages(bool isPaused) {
    throw UnimplementedError('pauseInAppMessages() has not been implemented.');
  }
}
