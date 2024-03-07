import 'package:reteno_plugin/src/models/anonymous_user_attributes.dart';
import 'package:reteno_plugin/src/models/reteno_custom_event.dart';
import 'package:reteno_plugin/src/models/reteno_custom_event_parameter.dart';
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
