import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reteno_plugin/reteno.dart';
import 'package:reteno_plugin/src/native_reteno_plugin.g.dart';
import 'package:reteno_plugin/src/reteno_plugin_pigeon_channel.dart';

class MockRetenoHostApi extends Mock implements RetenoHostApi {}

class MockNativeRetenoUser extends NativeRetenoUser {}

class MockNativeAnonymousUserAttributes extends NativeAnonymousUserAttributes {}

void main() {
  group('RetenoPigeonChannel', () {
    late RetenoPigeonChannel pigeonChannel;
    late MockRetenoHostApi mockApi;

    setUp(() {
      mockApi = MockRetenoHostApi();
      pigeonChannel = RetenoPigeonChannel.instanceWithApi(mockApi);
    });

    setUpAll(() async {
      WidgetsFlutterBinding.ensureInitialized();
      registerFallbackValue(MockNativeRetenoUser());
      registerFallbackValue(MockNativeAnonymousUserAttributes());
      registerFallbackValue(
        NativeNotificationGroupingRule(),
      );
    });

    test('setUserAttributes should call setUserAttributes on api', () async {
      const externalUserId = 'user123';
      final user = RetenoUser(
          userAttributes: UserAttributes(
        firstName: 'John',
        lastName: 'Doe',
      ));
      when(() => mockApi.setUserAttributes(externalUserId, any()))
          .thenAnswer((_) async => true);

      final result =
          await pigeonChannel.setUserAttributes(externalUserId, user);

      expect(result, true);
      verify(() => mockApi.setUserAttributes(externalUserId, any())).called(1);
    });

    test(
        'setAnonymousUserAttributes should call setAnonymousUserAttributes on api',
        () async {
      final anonymousUserAttributes =
          AnonymousUserAttributes(); // Provide appropriate object here
      when(() => mockApi.setAnonymousUserAttributes(any()))
          .thenAnswer((_) async => true);

      final result = await pigeonChannel
          .setAnonymousUserAttributes(anonymousUserAttributes);

      expect(result, true);
      verify(() => mockApi.setAnonymousUserAttributes(any())).called(1);
    });

    test('setPushToken trims and forwards token to api', () async {
      when(() => mockApi.setPushToken('fcm-token')).thenAnswer((_) async {});

      await pigeonChannel.setPushToken('  fcm-token  ');

      verify(() => mockApi.setPushToken('fcm-token')).called(1);
    });

    test('setPushToken rejects an empty token', () async {
      expect(
        () => pigeonChannel.setPushToken('   '),
        throwsArgumentError,
      );

      verifyNever(() => mockApi.setPushToken(any()));
    });

    test('setNotificationGroupingRule normalizes and forwards rule', () async {
      when(() => mockApi.setNotificationGroupingRule(any()))
          .thenAnswer((_) async {});

      await pigeonChannel.setNotificationGroupingRule(
        const RetenoNotificationGroupingRule.byPayloadKey(
          ' orderNumber ',
          fallbackGroupId: ' orders ',
        ),
      );

      final captured = verify(
        () => mockApi.setNotificationGroupingRule(captureAny()),
      ).captured.single as NativeNotificationGroupingRule;
      expect(captured.payloadKey, 'orderNumber');
      expect(captured.fallbackGroupId, 'orders');
    });

    test('setNotificationGroupingRule supports a constant group', () async {
      when(() => mockApi.setNotificationGroupingRule(any()))
          .thenAnswer((_) async {});

      await pigeonChannel.setNotificationGroupingRule(
        const RetenoNotificationGroupingRule.constant(' orders '),
      );

      final captured = verify(
        () => mockApi.setNotificationGroupingRule(captureAny()),
      ).captured.single as NativeNotificationGroupingRule;
      expect(captured.payloadKey, isNull);
      expect(captured.fallbackGroupId, 'orders');
    });

    test('setNotificationGroupingRule can clear rule', () async {
      when(() => mockApi.setNotificationGroupingRule(null))
          .thenAnswer((_) async {});

      await pigeonChannel.setNotificationGroupingRule(null);

      verify(() => mockApi.setNotificationGroupingRule(null)).called(1);
    });

    test('setNotificationGroupingRule rejects an empty rule', () async {
      expect(
        () => pigeonChannel.setNotificationGroupingRule(
          const RetenoNotificationGroupingRule.constant('   '),
        ),
        throwsArgumentError,
      );

      verifyNever(() => mockApi.setNotificationGroupingRule(any()));
    });

    test('getInitialNotification should return initial notification', () async {
      final expectedNotification = {
        'title': 'Notification',
        'body': 'Hello World'
      };
      when(() => mockApi.getInitialNotification())
          .thenAnswer((_) async => expectedNotification);

      final result = await pigeonChannel.getInitialNotification();

      expect(result, expectedNotification);
      verify(() => mockApi.getInitialNotification()).called(1);
    });

    test('pauseInAppMessages should call pauseInAppMessages on api', () async {
      when(() => mockApi.pauseInAppMessages(true))
          .thenAnswer((_) async => true);

      await pigeonChannel.pauseInAppMessages(true);

      verify(() => mockApi.pauseInAppMessages(true)).called(1);
    });
  });
}
