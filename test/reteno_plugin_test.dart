import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:reteno_plugin/anonymous_user_attributes.dart';
import 'package:reteno_plugin/reteno_custom_event.dart';
import 'package:reteno_plugin/reteno_plugin_platform_interface.dart';
import 'package:reteno_plugin/reteno_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:reteno_plugin/reteno_user.dart';

class MockRetenoPluginPlatform
    with MockPlatformInterfaceMixin
    implements RetenoPluginPlatform {
  @override
  Future<bool> setUserAttributes(String externalUserId, RetenoUser? user) {
    throw UnimplementedError();
  }

  @override
  Future<Map<dynamic, dynamic>?> getInitialNotification() {
    throw UnimplementedError();
  }

  @override
  late StreamController<Map<String, dynamic>> onRetenoNotificationReceived;

  @override
  late StreamController<Map<String, dynamic>> onRetenoNotificationClicked;

  @override
  Future<bool> setAnonymousUserAttributes(
      AnonymousUserAttributes anonymousUserAttributes) {
    throw UnimplementedError();
  }

  @override
  Future<bool> logEvent({required RetenoCustomEvent event}) {
    throw UnimplementedError();
  }
}

void main() {
  final RetenoPluginPlatform initialPlatform = RetenoPluginPlatform.instance;

  test('$MethodChannelRetenoPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelRetenoPlugin>());
  });
}
