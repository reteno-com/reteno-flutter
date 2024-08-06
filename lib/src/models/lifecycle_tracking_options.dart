class LifecycleTrackingOptions {
  factory LifecycleTrackingOptions.all() => LifecycleTrackingOptions(
        appLifecycleEnabled: true,
        pushSubscriptionEnabled: true,
        sessionEventsEnabled: true,
      );

  factory LifecycleTrackingOptions.none() => LifecycleTrackingOptions(
        appLifecycleEnabled: false,
        pushSubscriptionEnabled: false,
        sessionEventsEnabled: false,
      );

  LifecycleTrackingOptions({
    required this.appLifecycleEnabled,
    required this.pushSubscriptionEnabled,
    required this.sessionEventsEnabled,
  });

  final bool appLifecycleEnabled;
  final bool pushSubscriptionEnabled;
  final bool sessionEventsEnabled;
}
