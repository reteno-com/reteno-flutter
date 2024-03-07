import 'package:reteno_plugin/src/models/reteno_user.dart';

class AnonymousUserAttributes {
  AnonymousUserAttributes({
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
  final Address? address;
  final List<UserCustomField>? fields;

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'languageCode': languageCode,
      'timeZone': timeZone,
      'address': address?.toMap(),
      'fields': fields?.map((e) => e.toMap()).toList(),
    };
  }
}
