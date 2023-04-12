import 'package:reteno_plugin/reteno_custom_event_parameter.dart';

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

  Map<String, dynamic> toMap() {
    return {
      'event_type_key': eventTypeKey,
      'date_occurred': dateOccurred.toUtc().toIso8601String(),
      'parameters': parameters.map((e) => e.toMap()).toList(),
      'force_push': forcePush,
    };
  }
}
