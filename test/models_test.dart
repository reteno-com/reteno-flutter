import 'package:flutter_test/flutter_test.dart';
import 'package:reteno_plugin/reteno.dart';
import 'package:reteno_plugin/src/extensions.dart';

void main() {
  group('RetenoUserExt', () {
    test('toNativeRetenoUser returns correct NativeRetenoUser', () {
      var retenoUser = RetenoUser(
        subscriptionKeys: ['key1', 'key2'],
        userAttributes: UserAttributes(phone: '1234567890'),
        groupNamesExclude: ['group1'],
        groupNamesInclude: ['group2'],
      );

      var nativeRetenoUser = retenoUser.toNativeRetenoUser();

      expect(nativeRetenoUser.subscriptionKeys, ['key1', 'key2']);
      expect(nativeRetenoUser.userAttributes!.phone, '1234567890');
      expect(nativeRetenoUser.groupNamesExclude, ['group1']);
      expect(nativeRetenoUser.groupNamesInclude, ['group2']);
    });
  });

  group('UserAttributesExt', () {
    test('toNativeUserAttributes returns correct NativeUserAttributes', () {
      var userAttributes = UserAttributes(phone: '1234567890');

      var nativeUserAttributes = userAttributes.toNativeUserAttributes();

      expect(nativeUserAttributes.phone, '1234567890');
    });
  });

  group('AnonymousUserAttributesExt', () {
    test(
        'toNativeAnonymousUserAttributes returns correct NativeAnonymousUserAttributes',
        () {
      var anonymousUserAttributes = AnonymousUserAttributes(
        firstName: 'John',
        lastName: 'Doe',
        languageCode: 'en',
        timeZone: 'GMT',
        // Add other fields as necessary
      );

      var nativeAnonymousUserAttributes =
          anonymousUserAttributes.toNativeAnonymousUserAttributes();

      expect(nativeAnonymousUserAttributes.firstName, 'John');
      expect(nativeAnonymousUserAttributes.lastName, 'Doe');
      expect(nativeAnonymousUserAttributes.languageCode, 'en');
      expect(nativeAnonymousUserAttributes.timeZone, 'GMT');
      // Add other assertions as necessary
    });
  });
}
