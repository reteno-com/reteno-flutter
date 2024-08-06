import 'package:reteno_plugin/src/models/anonymous_user_attributes.dart';
import 'package:reteno_plugin/src/models/in_app_message_status.dart';
import 'package:reteno_plugin/src/models/lifecycle_tracking_options.dart';
import 'package:reteno_plugin/src/models/reteno_custom_event.dart';
import 'package:reteno_plugin/src/models/reteno_custom_event_parameter.dart';
import 'package:reteno_plugin/src/models/reteno_recommendation.dart';
import 'package:reteno_plugin/src/models/reteno_recommendation_event.dart';
import 'package:reteno_plugin/src/models/reteno_user.dart';
import 'package:reteno_plugin/src/native_reteno_plugin.g.dart';

extension RetenoUserExt on RetenoUser {
  NativeRetenoUser toNativeRetenoUser() {
    return NativeRetenoUser(
      subscriptionKeys: subscriptionKeys,
      userAttributes: userAttributes?.toNativeUserAttributes(),
      groupNamesExclude: groupNamesExclude,
      groupNamesInclude: groupNamesInclude,
    );
  }
}

extension UserAttributesExt on UserAttributes {
  NativeUserAttributes toNativeUserAttributes() {
    return NativeUserAttributes(
      phone: phone,
      email: email,
      firstName: firstName,
      lastName: lastName,
      languageCode: languageCode,
      timeZone: timeZone,
      address: address?.toNativeAddress(),
      fields: fields?.map((e) => e.toNativeUserCustomField()).toList(),
    );
  }
}

extension AnonymousUserAttributesExt on AnonymousUserAttributes {
  NativeAnonymousUserAttributes toNativeAnonymousUserAttributes() {
    return NativeAnonymousUserAttributes(
      firstName: firstName,
      lastName: lastName,
      languageCode: languageCode,
      timeZone: timeZone,
      address: address?.toNativeAddress(),
      fields: fields?.map((e) => e.toNativeUserCustomField()).toList(),
    );
  }
}

extension AddressExt on Address {
  NativeAddress toNativeAddress() {
    return NativeAddress(
      address: address,
      postcode: postcode,
      region: region,
      town: town,
    );
  }
}

extension UserCustomFieldExt on UserCustomField {
  NativeUserCustomField toNativeUserCustomField() {
    return NativeUserCustomField(
      key: key,
      value: value,
    );
  }
}

extension RetenoCustomEventExt on RetenoCustomEvent {
  NativeCustomEvent toCustomEvent() {
    return NativeCustomEvent(
      eventTypeKey: eventTypeKey,
      dateOccurred: dateOccurred.toUtc().toIso8601String(),
      forcePush: forcePush,
      parameters: parameters.map((e) => e.toCustomEventParameter()).toList(),
    );
  }
}

extension RetenoCustomEventParameterExt on RetenoCustomEventParameter {
  NativeCustomEventParameter toCustomEventParameter() {
    return NativeCustomEventParameter(
      name: name,
      value: value,
    );
  }
}

extension NativeInAppMessageStatusExt on NativeInAppMessageStatus {
  InAppMessageStatus toInAppMessageStatus(NativeInAppMessageAction? action, String? error) {
    switch (this) {
      case NativeInAppMessageStatus.inAppShouldBeDisplayed:
        return InAppShouldBeDisplayed();
      case NativeInAppMessageStatus.inAppIsDisplayed:
        return InAppIsDisplayed();
      case NativeInAppMessageStatus.inAppShouldBeClosed:
        return InAppShouldBeClosed(
          action: action!.toInAppMessageAction(),
        );
      case NativeInAppMessageStatus.inAppIsClosed:
        return InAppIsClosed(
          action: action!.toInAppMessageAction(),
        );
      case NativeInAppMessageStatus.inAppReceivedError:
        return InAppReceivedError(
          errorMessage: error!,
        );
    }
  }
}

extension NativeInAppMessageActionExt on NativeInAppMessageAction {
  InAppMessageAction toInAppMessageAction() {
    return InAppMessageAction(
      isCloseButtonClicked: isCloseButtonClicked,
      isButtonClicked: isButtonClicked,
      isOpenUrlClicked: isOpenUrlClicked,
    );
  }
}

extension RetenoRecomendationFilterExt on RetenoRecomendationFilter {
  NativeRecomFilter toNativeRecomFilter() {
    return NativeRecomFilter(
      name: name,
      values: values,
    );
  }
}

extension NativeRecommendationExt on NativeRecommendation {
  RetenoRecommendation toRetenoRecommendation() {
    return RetenoRecommendation(
      productId: productId,
      name: name,
      price: price,
      description: description,
      imageUrl: imageUrl,
    );
  }
}

extension RetenoRecomEventsExt on RetenoRecomEvents {
  NativeRecomEvents toNativeRecomEvents() {
    return NativeRecomEvents(
      recomVariantId: recomVariantId,
      events: events.map((e) => e!.toNativeRecomEvent()).toList(),
    );
  }
}

extension RetenoRecomEventExt on RetenoRecomEvent {
  NativeRecomEvent toNativeRecomEvent() {
    return NativeRecomEvent(
      eventType: eventType.toNativeRecomEventType(),
      dateOccurred: dateOccurred.toUtc().toIso8601String(),
      productId: productId,
    );
  }
}

extension RetenoRecomEventTypeExt on RetenoRecomEventType {
  NativeRecomEventType toNativeRecomEventType() {
    switch (this) {
      case RetenoRecomEventType.impression:
        return NativeRecomEventType.impression;
      case RetenoRecomEventType.click:
        return NativeRecomEventType.click;
    }
  }
}

extension LifecycleTrackingOptionsExt on LifecycleTrackingOptions {
  NativeLifecycleTrackingOptions toNativeLifecycleTrackingOptions() {
    return NativeLifecycleTrackingOptions(
      appLifecycleEnabled: appLifecycleEnabled,
      pushSubscriptionEnabled: pushSubscriptionEnabled,
      sessionEventsEnabled: sessionEventsEnabled,
    );
  }
}
