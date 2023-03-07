import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:reteno_plugin/anonymous_user_attributes.dart';
import 'package:reteno_plugin/reteno_user.dart';

import 'reteno_plugin_platform_interface.dart';

/// An implementation of [RetenoPluginPlatform] that uses method channels.
class MethodChannelRetenoPlugin extends RetenoPluginPlatform {
  MethodChannelRetenoPlugin() {
    methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onRetenoNotificationReceived':
          RetenoPluginPlatform.instance.onRetenoNotificationReceived
              .add(Map<String, dynamic>.from(call.arguments));
          break;
        default:
      }
    });
  }

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('reteno_plugin');

  @override
  Future<bool> setUserAttributes(
      String externalUserId, RetenoUser? user) async {
    var res = await methodChannel.invokeMethod<bool>(
      'setUserAttributes',
      {
        'externalUserId': externalUserId,
        'user_info': user?.toMap(),
      },
    );
    return res ?? false;
  }

  @override
  Future<bool> setAnonymousUserAttributes(
      AnonymousUserAttributes anonymousUserAttributes) async {
    var res = await methodChannel.invokeMethod<bool>(
      'setAnonymousUserAttributes',
      {
        'anonymousUserAttributes': anonymousUserAttributes.toMap(),
      },
    );
    return res ?? false;
  }

  @override
  Future<Map<dynamic, dynamic>?> getInitialNotification() async {
    var res = await methodChannel.invokeMapMethod('getInitialNotification');
    if (res == null) {
      return null;
    }
    return Map<String, dynamic>.from(res);
  }
}
