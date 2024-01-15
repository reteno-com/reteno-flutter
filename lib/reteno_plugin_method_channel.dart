import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:reteno_plugin/anonymous_user_attributes.dart';
import 'package:reteno_plugin/reteno_custom_event.dart';
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
        case 'onRetenoNotificationClicked':
          RetenoPluginPlatform.instance.onRetenoNotificationClicked
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
    final res = await methodChannel.invokeMethod<bool>(
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
    final res = await methodChannel.invokeMethod<bool>(
      'setAnonymousUserAttributes',
      {
        'anonymousUserAttributes': anonymousUserAttributes.toMap(),
      },
    );
    return res ?? false;
  }

  @override
  Future<Map<dynamic, dynamic>?> getInitialNotification() async {
    final res = await methodChannel.invokeMapMethod('getInitialNotification');
    if (res == null) {
      return null;
    }
    return Map<String, dynamic>.from(res);
  }

  @override
  Future<bool> logEvent({
    required RetenoCustomEvent event,
  }) async {
    final res = await methodChannel.invokeMethod<bool>(
      'logEvent',
      {'event': event.toMap()},
    );
    if (res == null) {
      return false;
    }
    return res;
  }
  
  @override
  Future<bool> updatePushPermissionStatus() async {
    if (Platform.isIOS) {
      return true;
    }
    final res =
        await methodChannel.invokeMethod<bool>('updatePushPermissionStatus');

    return res == true;
  }
}
