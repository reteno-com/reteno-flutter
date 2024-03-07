import 'package:reteno_plugin/src/models/reteno_custom_event_parameter.dart';

class RetenoCustomEvent {
  RetenoCustomEvent({
    required this.eventTypeKey,
    required this.dateOccurred,
    this.forcePush = false,
    required this.parameters,
  });

  final String eventTypeKey;
  final DateTime dateOccurred;
  final List<RetenoCustomEventParameter> parameters;
  final bool forcePush;

  // CustomEvent toCustomEvent() {
  //   return CustomEvent(
  //     eventTypeKey: eventTypeKey,
  //     dateOccurred: dateOccurred.toUtc().toIso8601String(),
  //     forcePush: forcePush,
  //     parameters: parameters.map((e) => e.toCustomEventParameter()).toList(),
  //   );
  // }

  @override
  String toString() {
    return 'RetenoCustomEvent{eventTypeKey: $eventTypeKey, dateOccurred: $dateOccurred, forcePush: $forcePush, parameters: $parameters}';
  }
}
