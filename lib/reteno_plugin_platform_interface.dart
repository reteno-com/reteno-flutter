import 'dart:async';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:reteno_plugin/anonymous_user_attributes.dart';
import 'package:reteno_plugin/reteno_custom_event.dart';
import 'package:reteno_plugin/reteno_user.dart';

import 'reteno_plugin_method_channel.dart';

abstract class RetenoPluginPlatform extends PlatformInterface {
  /// Constructs a RetenoPluginPlatform.
  RetenoPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static RetenoPluginPlatform _instance = MethodChannelRetenoPlugin();

  /// The default instance of [RetenoPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelRetenoPlugin].
  static RetenoPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [RetenoPluginPlatform] when
  /// they register themselves.
  static set instance(RetenoPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

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
}
