class RetenoDefaultNotificationChannelConfig {
  const RetenoDefaultNotificationChannelConfig({
    this.name,
    this.description,
    this.showBadge,
    this.lightsEnabled,
    this.vibrationEnabled,
  });

  final String? name;
  final String? description;
  final bool? showBadge;
  final bool? lightsEnabled;
  final bool? vibrationEnabled;
}
