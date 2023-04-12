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

  static Stream<Map<String, dynamic>> get onRetenoNotificationReceived =>
      RetenoPluginPlatform.instance.onRetenoNotificationReceived.stream;

  Future<dynamic> getInitialNotification() {
    return RetenoPluginPlatform.instance.getInitialNotification();
  }

  Future<bool> logEvent({
    required RetenoCustomEvent event,
  }) {
    return RetenoPluginPlatform.instance.logEvent(event: event);
  }
}
