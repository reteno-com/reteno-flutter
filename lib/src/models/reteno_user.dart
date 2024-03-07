import 'dart:core';

class RetenoUser {
  RetenoUser({
    this.subscriptionKeys,
    this.userAttributes,
    this.groupNamesExclude,
    this.groupNamesInclude,
  });

  final UserAttributes? userAttributes;
  final List<String>? subscriptionKeys;
  final List<String>? groupNamesInclude;
  final List<String>? groupNamesExclude;

  Map<String, dynamic> toMap() {
    return {
      'userAttributes': userAttributes?.toMap(),
      'subscriptionKeys': subscriptionKeys,
      'groupNamesInclude': groupNamesInclude,
      'groupNamesExclude': groupNamesExclude,
    };
  }
}

class UserAttributes {
  UserAttributes({
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
  final Address? address;
  final List<UserCustomField>? fields;

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'languageCode': languageCode,
      'timeZone': timeZone,
      'address': address?.toMap(),
      'fields': fields?.map((e) => e.toMap()).toList(),
    };
  }
}

class Address {
  Address({
    this.address,
    this.postcode,
    this.region,
    this.town,
  });
  final String? region;
  final String? town;
  final String? address;
  final String? postcode;

  Map<String, dynamic> toMap() {
    return {
      'region': region,
      'town': town,
      'address': address,
      'postcode': postcode,
    };
  }
}

class UserCustomField {
  UserCustomField({
    required this.key,
    this.value,
  });
  final String key;
  final String? value;

  Map<String, dynamic> toMap() {
    return {'key': key, 'value': value};
  }
}
