import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/native_reteno_plugin.g.dart',
    swiftOut: 'ios/Classes/pigeons/RetenoNativePlugin.swift',
    kotlinOptions: KotlinOptions(
      package: 'com.reteno.reteno_plugin',
    ),
    kotlinOut:
        'android/src/main/kotlin/com/reteno/reteno_plugin/RetenoHostApi.kt',
  ),
)
@HostApi()
abstract class RetenoHostApi {
  void setUserAttributes(String externalUserId, NativeRetenoUser? user);
  void setAnonymousUserAttributes(
      NativeAnonymousUserAttributes anonymousUserAttributes);
  void logEvent(NativeCustomEvent event);
  void updatePushPermissionStatus();
  void pauseInAppMessages(bool isPaused);
  Map<String, Object>? getInitialNotification();
  @async
  List<NativeRecommendation> getRecommendations({
    required String recomVariantId,
    required List<String> productIds,
    required String categoryId,
    List<NativeRecomFilter>? filters,
    List<String>? fields,
  });
  void logRecommendationsEvent(NativeRecomEvents events);
}

@FlutterApi()
abstract class RetenoFlutterApi {
  void onNotificationReceived(Map<String, Object?> payload);
  void onNotificationClicked(Map<String, Object?> payload);
  void onInAppMessageStatusChanged(
    NativeInAppMessageStatus status,
    NativeInAppMessageAction? action,
    String? error,
  );
}

class NativeRetenoUser {
  NativeRetenoUser({
    this.subscriptionKeys,
    this.userAttributes,
    this.groupNamesExclude,
    this.groupNamesInclude,
  });

  final NativeUserAttributes? userAttributes;
  final List<String?>? subscriptionKeys;
  final List<String?>? groupNamesInclude;
  final List<String?>? groupNamesExclude;
}

class NativeUserAttributes {
  NativeUserAttributes({
    this.lastName,
    this.firstName,
    this.address,
    this.email,
    this.fields,
    this.languageCode,
    this.phone,
    this.timeZone,
  });
  final String? phone;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? languageCode;
  final String? timeZone;
  final NativeAddress? address;
  final List<NativeUserCustomField?>? fields;
}

class NativeAddress {
  NativeAddress({
    this.address,
    this.postcode,
    this.region,
    this.town,
  });
  final String? region;
  final String? town;
  final String? address;
  final String? postcode;
}

class NativeUserCustomField {
  NativeUserCustomField({
    required this.key,
    this.value,
  });
  final String key;
  final String? value;
}

class NativeAnonymousUserAttributes {
  NativeAnonymousUserAttributes({
    this.lastName,
    this.firstName,
    this.address,
    this.fields,
    this.languageCode,
    this.timeZone,
  });
  final String? firstName;
  final String? lastName;
  final String? languageCode;
  final String? timeZone;
  final NativeAddress? address;
  final List<NativeUserCustomField?>? fields;
}

class NativeCustomEvent {
  NativeCustomEvent({
    required this.eventTypeKey,
    required this.dateOccurred,
    this.forcePush = false,
    required this.parameters,
  });

  final String eventTypeKey;
  final String dateOccurred;
  final List<NativeCustomEventParameter?> parameters;
  final bool forcePush;
}

class NativeCustomEventParameter {
  NativeCustomEventParameter(this.name, this.value);

  final String name;
  final String? value;
}

enum NativeInAppMessageStatus {
  inAppShouldBeDisplayed,
  inAppIsDisplayed,
  inAppShouldBeClosed,
  inAppIsClosed,
  inAppReceivedError
}

class NativeInAppMessageAction {
  NativeInAppMessageAction({
    required this.isCloseButtonClicked,
    required this.isButtonClicked,
    required this.isOpenUrlClicked,
  });

  final bool isCloseButtonClicked;
  final bool isButtonClicked;
  final bool isOpenUrlClicked;
}

class NativeRecomFilter {
  const NativeRecomFilter({required this.name, required this.values});
  final String name;
  final List<String?> values;
}

class NativeRecommendation {
  const NativeRecommendation({
    required this.productId,
    this.name,
    this.price,
    this.description,
    this.imageUrl,
  });
  final String productId;
  final String? name;
  final String? description;
  final String? imageUrl;
  final double? price;
}

enum NativeRecomEventType {
  impression,
  click,
}

class NativeRecomEvent {
  NativeRecomEvent({
    required this.eventType,
    required this.dateOccurred,
    required this.productId,
  });

  final NativeRecomEventType eventType;
  final String dateOccurred;
  final String productId;
}

class NativeRecomEvents {
  NativeRecomEvents({
    required this.recomVariantId,
    required this.events,
  });

  final String recomVariantId;
  final List<NativeRecomEvent?> events;
}
