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
  });
}
