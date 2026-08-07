import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reteno_plugin/reteno.dart';
import 'package:reteno_plugin/src/native_reteno_plugin.g.dart';
import 'package:reteno_plugin/src/reteno_plugin_pigeon_channel.dart';

class MockRetenoHostApi extends Mock implements RetenoHostApi {}

class MockNativeRetenoUser extends NativeRetenoUser {}

class MockNativeAnonymousUserAttributes extends NativeAnonymousUserAttributes {}

void stubInitialization(
  MockRetenoHostApi api, {
  required bool useCustomDeviceIdProvider,
  required String? customDeviceIdValue,
  void Function()? onCall,
}) {
  when(
    () => api.initWith(
      accessKey: 'access-key',
      lifecycleTrackingOptions: null,
      isPausedInAppMessages: false,
      useCustomDeviceIdProvider: useCustomDeviceIdProvider,
      customDeviceIdValue: customDeviceIdValue,
      isDebug: false,
      deviceTokenHandlingMode: NativeDeviceTokenHandlingMode.automatic,
      defaultNotificationChannelConfig: null,
    ),
  ).thenAnswer((_) async => onCall?.call());
}

void verifyInitialization(
  MockRetenoHostApi api, {
  required bool useCustomDeviceIdProvider,
  required String? customDeviceIdValue,
}) {
  verify(
    () => api.initWith(
      accessKey: 'access-key',
      lifecycleTrackingOptions: null,
      isPausedInAppMessages: false,
      useCustomDeviceIdProvider: useCustomDeviceIdProvider,
      customDeviceIdValue: customDeviceIdValue,
      isDebug: false,
      deviceTokenHandlingMode: NativeDeviceTokenHandlingMode.automatic,
      defaultNotificationChannelConfig: null,
    ),
  ).called(1);
}

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

    test('awaits customDeviceId before native init and forwards its value',
        () async {
      final providerResult = Completer<String?>();
      final order = <String>[];
      var providerCalls = 0;
      stubInitialization(
        mockApi,
        useCustomDeviceIdProvider: true,
        customDeviceIdValue: 'custom-device-id',
        onCall: () => order.add('native-init'),
      );

      final initialization = pigeonChannel.initWith(
        accessKey: 'access-key',
        customDeviceId: () async {
          providerCalls++;
          order.add('provider-start');
          final value = await providerResult.future;
          order.add('provider-finish');
          return value;
        },
      );

      await Future<void>.delayed(Duration.zero);
      expect(order, ['provider-start']);
      verifyNoMoreInteractions(mockApi);

      providerResult.complete('custom-device-id');
      await initialization;

      expect(providerCalls, 1);
      expect(order, ['provider-start', 'provider-finish', 'native-init']);
      verifyInitialization(
        mockApi,
        useCustomDeviceIdProvider: true,
        customDeviceIdValue: 'custom-device-id',
      );
    });

    test('uses the platform default for a null customDeviceId result',
        () async {
      var providerCalls = 0;
      stubInitialization(
        mockApi,
        useCustomDeviceIdProvider: false,
        customDeviceIdValue: null,
      );

      await pigeonChannel.initWith(
        accessKey: 'access-key',
        customDeviceId: () async {
          providerCalls++;
          return null;
        },
      );

      expect(providerCalls, 1);
      verifyInitialization(
        mockApi,
        useCustomDeviceIdProvider: false,
        customDeviceIdValue: null,
      );
    });

    test('rejects a blank customDeviceId before native init', () async {
      await expectLater(
        pigeonChannel.initWith(
          accessKey: 'access-key',
          customDeviceId: () async => '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );

      verifyNoMoreInteractions(mockApi);
    });

    test('does not call native init when customDeviceId throws', () async {
      final providerError = StateError('device ID unavailable');

      await expectLater(
        pigeonChannel.initWith(
          accessKey: 'access-key',
          customDeviceId: () async => throw providerError,
        ),
        throwsA(same(providerError)),
      );

      verifyNoMoreInteractions(mockApi);
    });

    test('disables the custom provider when customDeviceId is omitted',
        () async {
      stubInitialization(
        mockApi,
        useCustomDeviceIdProvider: false,
        customDeviceIdValue: null,
      );

      await pigeonChannel.initWith(accessKey: 'access-key');

      verifyInitialization(
        mockApi,
        useCustomDeviceIdProvider: false,
        customDeviceIdValue: null,
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
