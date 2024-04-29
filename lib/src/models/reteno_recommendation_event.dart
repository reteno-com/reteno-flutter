enum RetenoRecomEventType {
  impression,
  click,
}

class RetenoRecomEvent {
  const RetenoRecomEvent({
    required this.eventType,
    required this.dateOccurred,
    required this.productId,
  });

  final RetenoRecomEventType eventType;
  final DateTime dateOccurred;
  final String productId;
}

/// Recommendation events
///
/// Represents a group of recommendation events to be logged.
///
/// [recomVariantId] - recommendation variant ID
/// [events] - list of `RetenoRecomEvent` recommendation events
///     - [eventType] - event type
///         - `impression` - events describing that a specific product recommendation was shown to a user
///         - `click` - events describing that a user clicked a specific product recommendation
///     - [dateOccurred] - time when event occurred
///     - [productId] - product ID
class RetenoRecomEvents {
  const RetenoRecomEvents({
    required this.recomVariantId,
    required this.events,
  });

  final String recomVariantId;
  final List<RetenoRecomEvent?> events;
}
