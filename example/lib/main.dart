// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' show Random;
import 'dart:ui';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:reteno_plugin/reteno.dart';
import 'package:reteno_plugin_example/app_inbox_messages_page.dart';
import 'package:reteno_plugin_example/ecommerce_events.dart';
import 'package:reteno_plugin_example/events_page.dart';
import 'package:reteno_plugin_example/recommendation_page.dart';
import 'package:reteno_plugin_example/widgets/app_inbox_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const String _firebaseLogTag = 'FirebaseMessaging';
const String _retenoPluginLogTag = 'RetenoPlugin';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('notification_id', message.messageId?.toString() ?? 'null');

  print("$_firebaseLogTag: _firebaseMessagingBackgroundHandler:\n ${message.messageId}");
}

// The callback function should always be a top-level function.
@pragma('vm:entry-point')
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  int _eventCount = 0;

  // Called when the task is started.
  @override
  void onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;

    // You can use the getData function to get the stored data.
    final customData = await FlutterForegroundTask.getData<String>(key: 'customData');
    print('customData: $customData');
  }

  // Called every [interval] milliseconds in [ForegroundTaskOptions].
  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    FlutterForegroundTask.updateService(
      notificationTitle: 'MyTaskHandler',
      notificationText: 'eventCount: $_eventCount',
    );

    // Send data to the main isolate.
    sendPort?.send(_eventCount);

    _eventCount++;
  }

  // Called when the notification button on the Android platform is pressed.
  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) async {
    print('onDestroy');
  }

  // Called when the notification button on the Android platform is pressed.
  @override
  void onNotificationButtonPressed(String id) {
    print('onNotificationButtonPressed >> $id');
  }

  // Called when the notification itself on the Android platform is pressed.
  //
  // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
  // this function to be called.
  @override
  void onNotificationPressed() {
    // Note that the app will only route to "/resume-route" when it is exited so
    // it will usually be necessary to send a message through the send port to
    // signal it to restore state when the app is already started.
    FlutterForegroundTask.launchApp("/");
    _sendPort?.send('onNotificationPressed');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  if (Platform.isAndroid) {
    await Reteno().initWith(
      accessKey: '630A66AF-C1D3-4F2A-ACC1-0D51C38D2B05',
      lifecycleTrackingOptions: LifecycleTrackingOptions.all(),
    );
  }

  runApp(const MyApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const MyHomePage(title: 'Flutter Demo Home Page');
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'log_events',
          builder: (BuildContext context, GoRouterState state) {
            return const EventsPage();
          },
        ),
        GoRoute(
          path: 'recommendations',
          builder: (BuildContext context, GoRouterState state) {
            return const RecommendationPage();
          },
        ),
        GoRoute(
          path: 'ecommerce',
          builder: (BuildContext context, GoRouterState state) {
            return const EcommerceEventsPage();
          },
        ),
        GoRoute(
          path: 'appInbox',
          name: 'app-inbox-page',
          builder: (BuildContext context, GoRouterState state) {
            return const AppInboxMessagesPage();
          },
        ),
      ],
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Reteno Plugin Example',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        useMaterial3: false,
      ),
      routerConfig: _router,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<void> _showAlert(BuildContext context, String text) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: SingleChildScrollView(child: Text(text)),
    ));
  }

  final Reteno _reteno = Reteno();

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<String>? _stringLinkSubscription;
  ReceivePort? _receivePort;

  @override
  void initState() {
    super.initState();

    try {
      _reteno.getInitialNotification().then((value) {
        if (value != null) {
          print('$_retenoPluginLogTag: getInitialNotification: ${value.toString()}');
          _showAlert(context, '$_retenoPluginLogTag: getInitialNotification: ${value.toString()}');
        } else {
          print('$_retenoPluginLogTag: getInitialNotification: null');
          _showAlert(context, '$_retenoPluginLogTag: getInitialNotification: null');
        }
      }).onError((error, stackTrace) {
        print('$_retenoPluginLogTag: getInitialNotification: $error');
        print('$_retenoPluginLogTag: getInitialNotification: $stackTrace');
        _showAlert(context, '$_retenoPluginLogTag: getInitialNotification: $error');
        return null;
      });
    } catch (e) {
      print('$_retenoPluginLogTag: getInitialNotification: $e');
      _showAlert(context, '$_retenoPluginLogTag: getInitialNotification: $e');
    }

    Reteno.onRetenoNotificationReceived.listen((event) {
      print('$_retenoPluginLogTag: onRetenoNotificationReceived: ${event.toString()}');
      _showAlert(context, '$_retenoPluginLogTag: onRetenoNotificationReceived: ${event.toString()}');
    });
    Reteno.onRetenoNotificationClicked.listen((event) {
      print('$_retenoPluginLogTag: onRetenoClicked: ${event.toString()}');
      _showAlert(context, '$_retenoPluginLogTag: onRetenoClicked: ${event.toString()}');
    });

    Reteno.onUserNotificationAction.listen((event) {
      print('$_retenoPluginLogTag: onUserNotificationAction: ${event.toString()}');
      _showAlert(context, '$_retenoPluginLogTag: onUserNotificationAction: ${event.toString()}');
    });

    Reteno.onInAppMessageStatusChanged.listen((status) {
      switch (status) {
        case InAppShouldBeDisplayed():
          print('In-app should be displayed');
        case InAppIsDisplayed():
          print('In-app is displayed');
        case InAppShouldBeClosed(:final action):
          print('In-app should be closed $action');
        case InAppIsClosed(:final action):
          print('In-app is closed $action');
        case InAppReceivedError(:final errorMessage):
          print('In-app error: $errorMessage');
      }
    });

    _initFirebaseNotifications();
    initDeepLinks();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _requestPermissionForAndroid();
      _initForegroundTask();

      // You can get the previous ReceivePort without restarting the service.
      if (await FlutterForegroundTask.isRunningService) {
        final newReceivePort = FlutterForegroundTask.receivePort;
        _registerReceivePort(newReceivePort);
      }
    });
  }

  AndroidNotificationChannel channel = const AndroidNotificationChannel(
    'reteno_id', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.max,
  );

  Future<void> _initFirebaseNotifications() async {
    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      print('$_firebaseLogTag onMessageOpenedApp \n ${event.data}');
    });

    final message = await FirebaseMessaging.instance.getInitialMessage();
    print('$_firebaseLogTag getInitialMessage: $message');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('$_firebaseLogTag onMessage \n ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });
    FirebaseMessaging.instance.getToken().then((value) {
      print('$_firebaseLogTag getToken \n $value');
    });
  }

  Future<void> initDeepLinks() async {
    _appLinks = AppLinks();

    // Check initial link if app was in cold state (terminated)
    final appLink = await _appLinks.getInitialAppLink();
    if (appLink != null) {
      log('getInitialAppLink: $appLink');
      openAppLink(appLink);
    }

    // Handle link when app is in warm state (front or background)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      log('onAppLink: $uri');

      openAppLink(uri);
    });

    // _stringLinkSubscription = _appLinks.stringLinkStream.listen((uri) {
    //   log('onAppLink: $uri');
    //   //openAppLink(uri);
    // });
  }

  void openAppLink(Uri uri) {
    var path = uri.path;
    if (path.isEmpty) {
      path = '/${uri.authority}';
    }
    context.go(path);
    log(uri.toString());
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _stringLinkSubscription?.cancel();
    _closeReceivePort();
    super.dispose();
  }

  final _formKey = GlobalKey<FormBuilderState>();

  final ValueNotifier<bool> _isAnonymousUser = ValueNotifier<bool>(false);
  @override
  Widget build(BuildContext context) {
    InputDecoration inputDecoration(String labelText) => InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Colors.lightBlue,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reteno Example'),
        actions: [
          Row(
            children: [
              const Text('Anonymous User'),
              ValueListenableBuilder(
                valueListenable: _isAnonymousUser,
                builder: (context, value, _) {
                  return Switch(
                    value: value,
                    onChanged: (value) {
                      _isAnonymousUser.value = value;
                    },
                  );
                },
              ),
              const SizedBox(width: 8),
              const AppInboxButton(),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder(
            valueListenable: _isAnonymousUser,
            builder: (context, isAnonymousUser, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final result = await _startForegroundTask();
                              if (result && context.mounted) {
                                _showAlert(context, 'Foreground Task started');
                              } else if (context.mounted) {
                                _showAlert(context, 'Failed to start Foreground Task');
                              }
                            },
                            child: const Text('Start Foreground Task'),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final result = await _stopForegroundTask();
                              if (result && context.mounted) {
                                _showAlert(context, 'Foreground Task stopped');
                              } else if (context.mounted) {
                                _showAlert(context, 'Failed to stop Foreground Task');
                              }
                            },
                            child: const Text('Stop Foreground Task'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ElevatedButton(
                      onPressed: () async {
                        // FlutterAppBadger.removeBadge();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.reload();
                        print(prefs.getString('notification_id'));
                        if (context.mounted) {
                          _showAlert(context, '$_retenoPluginLogTag: ${prefs.getString('notification_id')}');
                        }
                      },
                      child: const Text(
                        'Get latest notification id that was consumed in background',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (await Permission.notification.isGranted) {
                          final res = await _reteno.updatePushPermissionStatus();
                          print(res);
                          return;
                        }
                        final permissionStatus = await Permission.notification.request();
                        if (permissionStatus.isGranted) {
                          final res = await _reteno.updatePushPermissionStatus();
                          print(res);
                        }
                      },
                      child: const Text(
                        'Update permission status',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: FormBuilder(
                            key: _formKey,
                            onChanged: () {
                              _formKey.currentState!.save();
                            },
                            autovalidateMode: AutovalidateMode.disabled,
                            initialValue: {
                              if (!isAnonymousUser) 'externalUserId': null,
                              if (!isAnonymousUser) 'phone': null,
                              if (!isAnonymousUser) 'email': null,
                              'first_name': null,
                              'last_name': null,
                              'language_code': null,
                              'timezone': null,
                              'region': null,
                              'town': null,
                              'address': null,
                              'postcode': null,
                              if (!isAnonymousUser) 'group_include': null,
                              if (!isAnonymousUser) 'group_exclude': null,
                              'additional_info': null,
                            },
                            skipDisabled: true,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                const SizedBox(height: 8),
                                const Text(
                                  'User attributes:',
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    backgroundColor: Colors.amber,
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (!isAnonymousUser)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FormBuilderTextField(
                                          name: 'externalUserId',
                                          decoration: inputDecoration('External User Id'),
                                          validator: FormBuilderValidators.compose([
                                            FormBuilderValidators.required(),
                                          ]),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8.0),
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            const uuid = Uuid();
                                            final generatedId = uuid.v4();
                                            _formKey.currentState?.fields['externalUserId']
                                                ?.didChange(generatedId.substring(0, 25));
                                          },
                                          child: const Text(
                                            'Generate',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                if (!isAnonymousUser) const SizedBox(height: 8),
                                if (!isAnonymousUser)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FormBuilderTextField(
                                          name: 'phone',
                                          decoration: inputDecoration('Phone number'),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8.0),
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            final random = Random();
                                            final randomPhoneNumber = random.nextInt(8999999) + 1000000;
                                            _formKey.currentState?.fields['phone']
                                                ?.didChange('+38068$randomPhoneNumber');
                                          },
                                          child: const Text(
                                            'Random',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                if (!isAnonymousUser) const SizedBox(height: 8),
                                if (!isAnonymousUser)
                                  FormBuilderTextField(
                                    name: 'email',
                                    decoration: inputDecoration('Email'),
                                  ),
                                const SizedBox(height: 8),
                                FormBuilderTextField(
                                  name: 'first_name',
                                  decoration: inputDecoration('First name'),
                                ),
                                const SizedBox(height: 8),
                                FormBuilderTextField(
                                  name: 'last_name',
                                  decoration: inputDecoration('Last name'),
                                ),
                                const SizedBox(height: 8),
                                FormBuilderTextField(
                                  name: 'language_code',
                                  decoration: inputDecoration('Language code'),
                                ),
                                const SizedBox(height: 8),
                                FormBuilderTextField(
                                  name: 'timezone',
                                  decoration: inputDecoration('Timezone'),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Address info:',
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    backgroundColor: Colors.amber,
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                FormBuilderTextField(
                                  name: 'region',
                                  decoration: inputDecoration('Region'),
                                ),
                                const SizedBox(height: 8),
                                FormBuilderTextField(
                                  name: 'town',
                                  decoration: inputDecoration('Town'),
                                ),
                                const SizedBox(height: 8),
                                FormBuilderTextField(
                                  name: 'address',
                                  decoration: inputDecoration('Address'),
                                ),
                                const SizedBox(height: 8),
                                FormBuilderTextField(
                                  name: 'postcode',
                                  decoration: inputDecoration('Postcode'),
                                ),
                                if (!isAnonymousUser) const SizedBox(height: 16),
                                if (!isAnonymousUser)
                                  FormBuilderTextField(
                                    name: 'groups_exclude',
                                    decoration: inputDecoration('Groups to exclude'),
                                  ),
                                if (!isAnonymousUser) const SizedBox(height: 8),
                                if (!isAnonymousUser)
                                  FormBuilderTextField(
                                    name: 'groups_include',
                                    decoration: inputDecoration('Groups to include'),
                                  ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Additional Info(Custom Field TEXT):',
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    backgroundColor: Colors.amber,
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FormBuilderTextField(
                                  name: 'additional_info',
                                  decoration: inputDecoration('Value for custom field TEXT'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (isAnonymousUser) {
                                    await updateAnonymousUserAttributes();
                                  } else {
                                    await updateUserAttributes();
                                  }
                                },
                                child: const Text(
                                  'Update User Attributes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  context.go('/log_events');
                                },
                                child: const Text(
                                  'Go to custom events page',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  context.go('/recommendations');
                                },
                                child: const Text(
                                  'Recommendations',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  context.go('/ecommerce');
                                },
                                child: const Text(
                                  'Ecommerce events',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
      ),
    );
  }

  Future<void> updateAnonymousUserAttributes() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final value = _formKey.currentState?.value;
      if (value == null) {
        return;
      }
      final customFields = <UserCustomField>[];
      if (value['additional_info']?.toString().isNotEmpty ?? false) {
        customFields.add(UserCustomField(key: 'ADDITIONAL_FIELDS.TEXT', value: value['additional_info']));
      }
      Address? userAddress;
      if (value['postcode']?.toString().isNotEmpty ??
          value['address']?.toString().isNotEmpty ??
          value['region']?.toString().isNotEmpty ??
          value['town']?.toString().isNotEmpty ??
          false) {
        userAddress = Address(
          postcode: value['postcode']?.toString(),
          address: value['address']?.toString(),
          region: value['region']?.toString(),
          town: value['town']?.toString(),
        );
      }

      final firstName = value['first_name']?.toString();
      final lastName = value['last_name']?.toString();
      final timezone = value['timezone']?.toString();
      final languageCode = value['language_code']?.toString();

      AnonymousUserAttributes? attributes;

      if ([firstName, lastName, timezone, languageCode].any((element) => element != null && element.isNotEmpty) ||
          userAddress != null) {
        attributes = AnonymousUserAttributes(
          firstName: firstName,
          lastName: lastName,
          timeZone: timezone,
          languageCode: languageCode,
          address: userAddress,
          fields: customFields,
        );
      }

      await _reteno.setAnomymousUserAttributes(
        anonymousUserAttributes: attributes ?? AnonymousUserAttributes(),
      );
    } else {
      debugPrint(_formKey.currentState?.value.toString());
      debugPrint('validation failed');
    }
  }

  Future<void> updateUserAttributes() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final value = _formKey.currentState?.value;
      if (value == null) {
        return;
      }
      final customFields = <UserCustomField>[];
      if (value['additional_info']?.toString().isNotEmpty ?? false) {
        customFields.add(UserCustomField(key: 'ADDITIONAL_FIELDS.TEXT', value: value['additional_info']));
      }
      Address? userAddress;
      if (value['postcode']?.toString().isNotEmpty ??
          value['address']?.toString().isNotEmpty ??
          value['region']?.toString().isNotEmpty ??
          value['town']?.toString().isNotEmpty ??
          false) {
        userAddress = Address(
          postcode: value['postcode']?.toString(),
          address: value['address']?.toString(),
          region: value['region']?.toString(),
          town: value['town']?.toString(),
        );
      }

      final email = value['email']?.toString();
      final firstName = value['first_name']?.toString();
      final lastName = value['last_name']?.toString();
      final phone = value['phone']?.toString();
      final timezone = value['timezone']?.toString();
      final languageCode = value['language_code']?.toString();

      UserAttributes? attributes;

      if ([email, firstName, lastName, phone, timezone, languageCode]
              .any((element) => element != null && element.isNotEmpty) ||
          userAddress != null) {
        attributes = UserAttributes(
          email: email,
          firstName: firstName,
          lastName: lastName,
          phone: phone,
          timeZone: timezone,
          languageCode: languageCode,
          address: userAddress,
          fields: customFields,
        );
      }

      final userInfo = RetenoUser(
        userAttributes: attributes,
        groupNamesExclude: value['groups_exclude']?.toString().split(',').map((e) => e.trim()).toList(),
        groupNamesInclude: value['groups_include']?.toString().split(',').map((e) => e.trim()).toList(),
      );

      await _reteno.setUserAttributes(
        userExternalId: value['externalUserId'],
        user: userInfo,
      );
    } else {
      debugPrint(_formKey.currentState?.value.toString());
      debugPrint('validation failed');
    }
  }

  Future<void> _requestPermissionForAndroid() async {
    if (!Platform.isAndroid) {
      return;
    }

    // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
    // onNotificationPressed function to be called.
    //
    // When the notification is pressed while permission is denied,
    // the onNotificationPressed function is not called and the app opens.
    //
    // If you do not use the onNotificationPressed or launchApp function,
    // you do not need to write this code.
    if (!await FlutterForegroundTask.canDrawOverlays) {
      // This function requires `android.permission.SYSTEM_ALERT_WINDOW` permission.
      await FlutterForegroundTask.openSystemAlertWindowSettings();
    }

    // Android 12 or higher, there are restrictions on starting a foreground service.
    //
    // To restart the service on device reboot or unexpected problem, you need to allow below permission.
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      // This function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    // Android 13 and higher, you need to allow notification permission to expose foreground service notification.
    final NotificationPermission notificationPermissionStatus =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermissionStatus != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        id: 500,
        channelId: 'foreground_service',
        channelName: 'Foreground Service Notification',
        channelDescription: 'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
          backgroundColor: Colors.orange,
        ),
        buttons: [
          const NotificationButton(
            id: 'sendButton',
            text: 'Send',
            textColor: Colors.orange,
          ),
          const NotificationButton(
            id: 'testButton',
            text: 'Test',
            textColor: Colors.grey,
          ),
        ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<bool> _startForegroundTask() async {
    // You can save data using the saveData function.
    await FlutterForegroundTask.saveData(key: 'customData', value: 'hello');

    // Register the receivePort before starting the service.
    final ReceivePort? receivePort = FlutterForegroundTask.receivePort;
    final bool isRegistered = _registerReceivePort(receivePort);
    if (!isRegistered) {
      print('Failed to register receivePort!');
      return false;
    }

    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    } else {
      return FlutterForegroundTask.startService(
        notificationTitle: 'Foreground Service is running',
        notificationText: 'Tap to return to the app',
        callback: startCallback,
      );
    }
  }

  Future<bool> _stopForegroundTask() async {
    final result = await FlutterForegroundTask.stopService();
    DartPluginRegistrant.ensureInitialized();
    return result;
  }

  bool _registerReceivePort(ReceivePort? newReceivePort) {
    if (newReceivePort == null) {
      return false;
    }

    _closeReceivePort();

    _receivePort = newReceivePort;
    _receivePort?.listen((data) {
      if (data is int) {
        print('eventCount: $data');
      } else if (data is String) {
        if (data == 'onNotificationPressed') {
          Navigator.of(context).pushNamed('/resume-route');
        }
      } else if (data is DateTime) {
        print('timestamp: ${data.toString()}');
      }
    });

    return _receivePort != null;
  }

  void _closeReceivePort() {
    _receivePort?.close();
    _receivePort = null;
  }
}
