/// Android push notification grouping configuration.
///
/// The rule is persisted by the native plugin so it can be applied when a push
/// arrives while the Flutter engine is not running.
class RetenoNotificationGroupingRule {
  /// Uses the same [groupId] for every Reteno push notification.
  const RetenoNotificationGroupingRule.constant(String groupId)
      : this._(fallbackGroupId: groupId);

  /// Uses the value stored under [payloadKey] in the push payload as group ID.
  ///
  /// [fallbackGroupId] is used when the payload does not contain a non-empty
  /// value for [payloadKey]. When it is `null`, that notification is not
  /// assigned to a group.
  const RetenoNotificationGroupingRule.byPayloadKey(
    String payloadKey, {
    String? fallbackGroupId,
  }) : this._(
          payloadKey: payloadKey,
          fallbackGroupId: fallbackGroupId,
        );

  const RetenoNotificationGroupingRule._({
    this.payloadKey,
    this.fallbackGroupId,
  });

  final String? payloadKey;
  final String? fallbackGroupId;
}
