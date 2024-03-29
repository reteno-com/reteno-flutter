// Autogenerated from Pigeon (v17.1.2), do not edit directly.
// See also: https://pub.dev/packages/pigeon
// ignore_for_file: public_member_api_docs, non_constant_identifier_names, avoid_as, unused_import, unnecessary_parenthesis, prefer_null_aware_operators, omit_local_variable_types, unused_shown_name, unnecessary_import, no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:typed_data' show Float64List, Int32List, Int64List, Uint8List;

import 'package:flutter/foundation.dart' show ReadBuffer, WriteBuffer;
import 'package:flutter/services.dart';

PlatformException _createConnectionError(String channelName) {
  return PlatformException(
    code: 'channel-error',
    message: 'Unable to establish connection on channel: "$channelName".',
  );
}

List<Object?> wrapResponse(
    {Object? result, PlatformException? error, bool empty = false}) {
  if (empty) {
    return <Object?>[];
  }
  if (error == null) {
    return <Object?>[result];
  }
  return <Object?>[error.code, error.message, error.details];
}

class NativeRetenoUser {
  NativeRetenoUser({
    this.userAttributes,
    this.subscriptionKeys,
    this.groupNamesInclude,
    this.groupNamesExclude,
  });

  NativeUserAttributes? userAttributes;

  List<String?>? subscriptionKeys;

  List<String?>? groupNamesInclude;

  List<String?>? groupNamesExclude;

  Object encode() {
    return <Object?>[
      userAttributes?.encode(),
      subscriptionKeys,
      groupNamesInclude,
      groupNamesExclude,
    ];
  }

  static NativeRetenoUser decode(Object result) {
    result as List<Object?>;
    return NativeRetenoUser(
      userAttributes: result[0] != null
          ? NativeUserAttributes.decode(result[0]! as List<Object?>)
          : null,
      subscriptionKeys: (result[1] as List<Object?>?)?.cast<String?>(),
      groupNamesInclude: (result[2] as List<Object?>?)?.cast<String?>(),
      groupNamesExclude: (result[3] as List<Object?>?)?.cast<String?>(),
    );
  }
}

class NativeUserAttributes {
  NativeUserAttributes({
    this.phone,
    this.email,
    this.firstName,
    this.lastName,
    this.languageCode,
    this.timeZone,
    this.address,
    this.fields,
  });

  String? phone;

  String? email;

  String? firstName;

  String? lastName;

  String? languageCode;

  String? timeZone;

  NativeAddress? address;

  List<NativeUserCustomField?>? fields;

  Object encode() {
    return <Object?>[
      phone,
      email,
      firstName,
      lastName,
      languageCode,
      timeZone,
      address?.encode(),
      fields,
    ];
  }

  static NativeUserAttributes decode(Object result) {
    result as List<Object?>;
    return NativeUserAttributes(
      phone: result[0] as String?,
      email: result[1] as String?,
      firstName: result[2] as String?,
      lastName: result[3] as String?,
      languageCode: result[4] as String?,
      timeZone: result[5] as String?,
      address: result[6] != null
          ? NativeAddress.decode(result[6]! as List<Object?>)
          : null,
      fields: (result[7] as List<Object?>?)?.cast<NativeUserCustomField?>(),
    );
  }
}

class NativeAddress {
  NativeAddress({
    this.region,
    this.town,
    this.address,
    this.postcode,
  });

  String? region;

  String? town;

  String? address;

  String? postcode;

  Object encode() {
    return <Object?>[
      region,
      town,
      address,
      postcode,
    ];
  }

  static NativeAddress decode(Object result) {
    result as List<Object?>;
    return NativeAddress(
      region: result[0] as String?,
      town: result[1] as String?,
      address: result[2] as String?,
      postcode: result[3] as String?,
    );
  }
}

class NativeUserCustomField {
  NativeUserCustomField({
    required this.key,
    this.value,
  });

  String key;

  String? value;

  Object encode() {
    return <Object?>[
      key,
      value,
    ];
  }

  static NativeUserCustomField decode(Object result) {
    result as List<Object?>;
    return NativeUserCustomField(
      key: result[0]! as String,
      value: result[1] as String?,
    );
  }
}

class NativeAnonymousUserAttributes {
  NativeAnonymousUserAttributes({
    this.firstName,
    this.lastName,
    this.languageCode,
    this.timeZone,
    this.address,
    this.fields,
  });

  String? firstName;

  String? lastName;

  String? languageCode;

  String? timeZone;

  NativeAddress? address;

  List<NativeUserCustomField?>? fields;

  Object encode() {
    return <Object?>[
      firstName,
      lastName,
      languageCode,
      timeZone,
      address?.encode(),
      fields,
    ];
  }

  static NativeAnonymousUserAttributes decode(Object result) {
    result as List<Object?>;
    return NativeAnonymousUserAttributes(
      firstName: result[0] as String?,
      lastName: result[1] as String?,
      languageCode: result[2] as String?,
      timeZone: result[3] as String?,
      address: result[4] != null
          ? NativeAddress.decode(result[4]! as List<Object?>)
          : null,
      fields: (result[5] as List<Object?>?)?.cast<NativeUserCustomField?>(),
    );
  }
}

class NativeCustomEvent {
  NativeCustomEvent({
    required this.eventTypeKey,
    required this.dateOccurred,
    required this.parameters,
    this.forcePush = false,
  });

  String eventTypeKey;

  String dateOccurred;

  List<NativeCustomEventParameter?> parameters;

  bool forcePush;

  Object encode() {
    return <Object?>[
      eventTypeKey,
      dateOccurred,
      parameters,
      forcePush,
    ];
  }

  static NativeCustomEvent decode(Object result) {
    result as List<Object?>;
    return NativeCustomEvent(
      eventTypeKey: result[0]! as String,
      dateOccurred: result[1]! as String,
      parameters:
          (result[2] as List<Object?>?)!.cast<NativeCustomEventParameter?>(),
      forcePush: result[3]! as bool,
    );
  }
}

class NativeCustomEventParameter {
  NativeCustomEventParameter({
    required this.name,
    this.value,
  });

  String name;

  String? value;

  Object encode() {
    return <Object?>[
      name,
      value,
    ];
  }

  static NativeCustomEventParameter decode(Object result) {
    result as List<Object?>;
    return NativeCustomEventParameter(
      name: result[0]! as String,
      value: result[1] as String?,
    );
  }
}

class _RetenoHostApiCodec extends StandardMessageCodec {
  const _RetenoHostApiCodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is NativeAddress) {
      buffer.putUint8(128);
      writeValue(buffer, value.encode());
    } else if (value is NativeAnonymousUserAttributes) {
      buffer.putUint8(129);
      writeValue(buffer, value.encode());
    } else if (value is NativeCustomEvent) {
      buffer.putUint8(130);
      writeValue(buffer, value.encode());
    } else if (value is NativeCustomEventParameter) {
      buffer.putUint8(131);
      writeValue(buffer, value.encode());
    } else if (value is NativeRetenoUser) {
      buffer.putUint8(132);
      writeValue(buffer, value.encode());
    } else if (value is NativeUserAttributes) {
      buffer.putUint8(133);
      writeValue(buffer, value.encode());
    } else if (value is NativeUserCustomField) {
      buffer.putUint8(134);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 128:
        return NativeAddress.decode(readValue(buffer)!);
      case 129:
        return NativeAnonymousUserAttributes.decode(readValue(buffer)!);
      case 130:
        return NativeCustomEvent.decode(readValue(buffer)!);
      case 131:
        return NativeCustomEventParameter.decode(readValue(buffer)!);
      case 132:
        return NativeRetenoUser.decode(readValue(buffer)!);
      case 133:
        return NativeUserAttributes.decode(readValue(buffer)!);
      case 134:
        return NativeUserCustomField.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

class RetenoHostApi {
  /// Constructor for [RetenoHostApi].  The [binaryMessenger] named argument is
  /// available for dependency injection.  If it is left null, the default
  /// BinaryMessenger will be used which routes to the host platform.
  RetenoHostApi({BinaryMessenger? binaryMessenger})
      : __pigeon_binaryMessenger = binaryMessenger;
  final BinaryMessenger? __pigeon_binaryMessenger;

  static const MessageCodec<Object?> pigeonChannelCodec = _RetenoHostApiCodec();

  Future<void> setUserAttributes(
      String externalUserId, NativeRetenoUser? user) async {
    const String __pigeon_channelName =
        'dev.flutter.pigeon.reteno_plugin.RetenoHostApi.setUserAttributes';
    final BasicMessageChannel<Object?> __pigeon_channel =
        BasicMessageChannel<Object?>(
      __pigeon_channelName,
      pigeonChannelCodec,
      binaryMessenger: __pigeon_binaryMessenger,
    );
    final List<Object?>? __pigeon_replyList = await __pigeon_channel
        .send(<Object?>[externalUserId, user]) as List<Object?>?;
    if (__pigeon_replyList == null) {
      throw _createConnectionError(__pigeon_channelName);
    } else if (__pigeon_replyList.length > 1) {
      throw PlatformException(
        code: __pigeon_replyList[0]! as String,
        message: __pigeon_replyList[1] as String?,
        details: __pigeon_replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> setAnonymousUserAttributes(
      NativeAnonymousUserAttributes anonymousUserAttributes) async {
    const String __pigeon_channelName =
        'dev.flutter.pigeon.reteno_plugin.RetenoHostApi.setAnonymousUserAttributes';
    final BasicMessageChannel<Object?> __pigeon_channel =
        BasicMessageChannel<Object?>(
      __pigeon_channelName,
      pigeonChannelCodec,
      binaryMessenger: __pigeon_binaryMessenger,
    );
    final List<Object?>? __pigeon_replyList = await __pigeon_channel
        .send(<Object?>[anonymousUserAttributes]) as List<Object?>?;
    if (__pigeon_replyList == null) {
      throw _createConnectionError(__pigeon_channelName);
    } else if (__pigeon_replyList.length > 1) {
      throw PlatformException(
        code: __pigeon_replyList[0]! as String,
        message: __pigeon_replyList[1] as String?,
        details: __pigeon_replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> logEvent(NativeCustomEvent event) async {
    const String __pigeon_channelName =
        'dev.flutter.pigeon.reteno_plugin.RetenoHostApi.logEvent';
    final BasicMessageChannel<Object?> __pigeon_channel =
        BasicMessageChannel<Object?>(
      __pigeon_channelName,
      pigeonChannelCodec,
      binaryMessenger: __pigeon_binaryMessenger,
    );
    final List<Object?>? __pigeon_replyList =
        await __pigeon_channel.send(<Object?>[event]) as List<Object?>?;
    if (__pigeon_replyList == null) {
      throw _createConnectionError(__pigeon_channelName);
    } else if (__pigeon_replyList.length > 1) {
      throw PlatformException(
        code: __pigeon_replyList[0]! as String,
        message: __pigeon_replyList[1] as String?,
        details: __pigeon_replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> updatePushPermissionStatus() async {
    const String __pigeon_channelName =
        'dev.flutter.pigeon.reteno_plugin.RetenoHostApi.updatePushPermissionStatus';
    final BasicMessageChannel<Object?> __pigeon_channel =
        BasicMessageChannel<Object?>(
      __pigeon_channelName,
      pigeonChannelCodec,
      binaryMessenger: __pigeon_binaryMessenger,
    );
    final List<Object?>? __pigeon_replyList =
        await __pigeon_channel.send(null) as List<Object?>?;
    if (__pigeon_replyList == null) {
      throw _createConnectionError(__pigeon_channelName);
    } else if (__pigeon_replyList.length > 1) {
      throw PlatformException(
        code: __pigeon_replyList[0]! as String,
        message: __pigeon_replyList[1] as String?,
        details: __pigeon_replyList[2],
      );
    } else {
      return;
    }
  }

  Future<Map<String?, Object?>?> getInitialNotification() async {
    const String __pigeon_channelName =
        'dev.flutter.pigeon.reteno_plugin.RetenoHostApi.getInitialNotification';
    final BasicMessageChannel<Object?> __pigeon_channel =
        BasicMessageChannel<Object?>(
      __pigeon_channelName,
      pigeonChannelCodec,
      binaryMessenger: __pigeon_binaryMessenger,
    );
    final List<Object?>? __pigeon_replyList =
        await __pigeon_channel.send(null) as List<Object?>?;
    if (__pigeon_replyList == null) {
      throw _createConnectionError(__pigeon_channelName);
    } else if (__pigeon_replyList.length > 1) {
      throw PlatformException(
        code: __pigeon_replyList[0]! as String,
        message: __pigeon_replyList[1] as String?,
        details: __pigeon_replyList[2],
      );
    } else {
      return (__pigeon_replyList[0] as Map<Object?, Object?>?)
          ?.cast<String?, Object?>();
    }
  }
}

class _RetenoFlutterApiCodec extends StandardMessageCodec {
  const _RetenoFlutterApiCodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is NativeAddress) {
      buffer.putUint8(128);
      writeValue(buffer, value.encode());
    } else if (value is NativeAnonymousUserAttributes) {
      buffer.putUint8(129);
      writeValue(buffer, value.encode());
    } else if (value is NativeCustomEvent) {
      buffer.putUint8(130);
      writeValue(buffer, value.encode());
    } else if (value is NativeCustomEventParameter) {
      buffer.putUint8(131);
      writeValue(buffer, value.encode());
    } else if (value is NativeRetenoUser) {
      buffer.putUint8(132);
      writeValue(buffer, value.encode());
    } else if (value is NativeUserAttributes) {
      buffer.putUint8(133);
      writeValue(buffer, value.encode());
    } else if (value is NativeUserCustomField) {
      buffer.putUint8(134);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 128:
        return NativeAddress.decode(readValue(buffer)!);
      case 129:
        return NativeAnonymousUserAttributes.decode(readValue(buffer)!);
      case 130:
        return NativeCustomEvent.decode(readValue(buffer)!);
      case 131:
        return NativeCustomEventParameter.decode(readValue(buffer)!);
      case 132:
        return NativeRetenoUser.decode(readValue(buffer)!);
      case 133:
        return NativeUserAttributes.decode(readValue(buffer)!);
      case 134:
        return NativeUserCustomField.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

abstract class RetenoFlutterApi {
  static const MessageCodec<Object?> pigeonChannelCodec =
      _RetenoFlutterApiCodec();

  void onNotificationReceived(Map<String?, Object?> payload);

  void onNotificationClicked(Map<String?, Object?> payload);

  static void setup(RetenoFlutterApi? api, {BinaryMessenger? binaryMessenger}) {
    {
      final BasicMessageChannel<Object?> __pigeon_channel = BasicMessageChannel<
              Object?>(
          'dev.flutter.pigeon.reteno_plugin.RetenoFlutterApi.onNotificationReceived',
          pigeonChannelCodec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        __pigeon_channel.setMessageHandler(null);
      } else {
        __pigeon_channel.setMessageHandler((Object? message) async {
          assert(message != null,
              'Argument for dev.flutter.pigeon.reteno_plugin.RetenoFlutterApi.onNotificationReceived was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final Map<String?, Object?>? arg_payload =
              (args[0] as Map<Object?, Object?>?)?.cast<String?, Object?>();
          assert(arg_payload != null,
              'Argument for dev.flutter.pigeon.reteno_plugin.RetenoFlutterApi.onNotificationReceived was null, expected non-null Map<String?, Object?>.');
          try {
            api.onNotificationReceived(arg_payload!);
            return wrapResponse(empty: true);
          } on PlatformException catch (e) {
            return wrapResponse(error: e);
          } catch (e) {
            return wrapResponse(
                error: PlatformException(code: 'error', message: e.toString()));
          }
        });
      }
    }
    {
      final BasicMessageChannel<Object?> __pigeon_channel = BasicMessageChannel<
              Object?>(
          'dev.flutter.pigeon.reteno_plugin.RetenoFlutterApi.onNotificationClicked',
          pigeonChannelCodec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        __pigeon_channel.setMessageHandler(null);
      } else {
        __pigeon_channel.setMessageHandler((Object? message) async {
          assert(message != null,
              'Argument for dev.flutter.pigeon.reteno_plugin.RetenoFlutterApi.onNotificationClicked was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final Map<String?, Object?>? arg_payload =
              (args[0] as Map<Object?, Object?>?)?.cast<String?, Object?>();
          assert(arg_payload != null,
              'Argument for dev.flutter.pigeon.reteno_plugin.RetenoFlutterApi.onNotificationClicked was null, expected non-null Map<String?, Object?>.');
          try {
            api.onNotificationClicked(arg_payload!);
            return wrapResponse(empty: true);
          } on PlatformException catch (e) {
            return wrapResponse(error: e);
          } catch (e) {
            return wrapResponse(
                error: PlatformException(code: 'error', message: e.toString()));
          }
        });
      }
    }
  }
}
