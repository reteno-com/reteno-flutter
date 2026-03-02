import 'package:reteno_plugin/src/models/lifecycle_tracking_options.dart';
import 'package:reteno_plugin/src/models/reteno_default_notification_channel_config.dart';
import 'package:reteno_plugin/src/models/reteno_device_token_handling_mode.dart';

class RetenoInitOptions {
  const RetenoInitOptions({
    this.isPausedInAppMessages = false,
    this.isDebug = false,
    this.lifecycleTrackingOptions,
    this.deviceTokenHandlingMode = RetenoDeviceTokenHandlingMode.automatic,
    this.defaultNotificationChannelConfig,
  });

  final bool isPausedInAppMessages;
  final bool isDebug;
  final LifecycleTrackingOptions? lifecycleTrackingOptions;
  final RetenoDeviceTokenHandlingMode deviceTokenHandlingMode;
  final RetenoDefaultNotificationChannelConfig?
      defaultNotificationChannelConfig;
}
