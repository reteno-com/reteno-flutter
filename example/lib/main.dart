// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:developer';
import 'dart:math' show Random;

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:reteno_plugin/anonymous_user_attributes.dart';
import 'package:reteno_plugin/reteno.dart';
import 'package:reteno_plugin/reteno_user.dart';
import 'package:reteno_plugin_example/events_page.dart';
import 'package:reteno_plugin_example/secrets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const String _firebaseLogTag = 'FirebaseMessaging';
const String _retenoPluginLogTag = 'RetenoPlugin';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('notification_id', message.messageId?.toString() ?? 'null');

  print(
      "$_firebaseLogTag: _firebaseMessagingBackgroundHandler:\n ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await SentryFlutter.init(
    (options) {
      options.dsn = Constants.sentryDsn;
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(const MyApp()),
  );

  // runApp(const MyApp());
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
          path: 'recom',
          builder: (BuildContext context, GoRouterState state) {
            return const EventsPage();
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

  @override
  void initState() {
    super.initState();

    _reteno.getInitialNotification().then((value) {
      if (value != null) {
        print(
            '$_retenoPluginLogTag: getInitialNotification: ${value.toString()}');
        _showAlert(context,
            '$_retenoPluginLogTag: getInitialNotification: ${value.toString()}');
      }
    });
    Reteno.onRetenoNotificationReceived.listen((event) {
      print(
          '$_retenoPluginLogTag: onRetenoNotificationReceived: ${event.toString()}');
      _showAlert(context,
          '$_retenoPluginLogTag: onRetenoNotificationReceived: ${event.toString()}');
    });
    Reteno.onRetenoNotificationClicked.listen((event) {
      print('$_retenoPluginLogTag: onRetenoClicked: ${event.toString()}');
      _showAlert(context,
          '$_retenoPluginLogTag: onRetenoClicked: ${event.toString()}');
    });
    _initFirebaseNotifications();
    initDeepLinks();
  }

  AndroidNotificationChannel channel = const AndroidNotificationChannel(
    'reteno_id', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
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
              const Text('Anonymous User  '),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.reload();
                        print(prefs.getString('notification_id'));
                        if (context.mounted) {
                          _showAlert(context,
                              '$_retenoPluginLogTag: ${prefs.getString('notification_id')}');
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
                                          decoration: inputDecoration(
                                              'External User Id'),
                                          validator:
                                              FormBuilderValidators.compose([
                                            FormBuilderValidators.required(),
                                          ]),
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8.0),
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            const uuid = Uuid();
                                            final generatedId = uuid.v4();
                                            _formKey.currentState
                                                ?.fields['externalUserId']
                                                ?.didChange(generatedId
                                                    .substring(0, 25));
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
                                          decoration:
                                              inputDecoration('Phone number'),
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8.0),
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            final random = Random();
                                            final randomPhoneNumber =
                                                random.nextInt(8999999) +
                                                    1000000;
                                            _formKey
                                                .currentState?.fields['phone']
                                                ?.didChange(
                                                    '+38068$randomPhoneNumber');
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
                                if (!isAnonymousUser)
                                  const SizedBox(height: 16),
                                if (!isAnonymousUser)
                                  FormBuilderTextField(
                                    name: 'groups_exclude',
                                    decoration:
                                        inputDecoration('Groups to exclude'),
                                  ),
                                if (!isAnonymousUser) const SizedBox(height: 8),
                                if (!isAnonymousUser)
                                  FormBuilderTextField(
                                    name: 'groups_include',
                                    decoration:
                                        inputDecoration('Groups to include'),
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
                                  decoration: inputDecoration(
                                      'Value for custom field TEXT'),
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
                    child: Row(
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
                              context.go('/recom');
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
        customFields.add(UserCustomField(
            key: 'ADDITIONAL_FIELDS.TEXT', value: value['additional_info']));
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

      if ([firstName, lastName, timezone, languageCode]
              .any((element) => element != null && element.isNotEmpty) ||
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
        customFields.add(UserCustomField(
            key: 'ADDITIONAL_FIELDS.TEXT', value: value['additional_info']));
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
        groupNamesExclude: value['groups_exclude']
            ?.toString()
            .split(',')
            .map((e) => e.trim())
            .toList(),
        groupNamesInclude: value['groups_include']
            ?.toString()
            .split(',')
            .map((e) => e.trim())
            .toList(),
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
}
