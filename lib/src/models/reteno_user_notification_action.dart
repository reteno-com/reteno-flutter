class RetenoUserNotificationAction {
  RetenoUserNotificationAction({
    this.actionId,
    this.customData,
    this.link,
  });

  final String? actionId;
  final Map<String?, Object?>? customData;
  final String? link;

  @override
  String toString() {
    return 'RetenoUserNotificationAction{actionId: $actionId, customData: $customData, link: $link}';
  }
}
