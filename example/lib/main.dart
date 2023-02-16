import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:reteno_plugin/reteno.dart';
import 'package:reteno_plugin/reteno_user.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Reteno Plugin Example',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  Future<void> _showAlert(BuildContext context, String text) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Push data"),
          content: SingleChildScrollView(child: Text(text)),
          actions: <Widget>[
            TextButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  final Reteno _reteno = Reteno();

  @override
  void initState() {
    super.initState();
    _reteno.getInitialNotification().then((value) {
      if (value != null) {
        _showAlert(context, value.toString());
      }
    });
    Reteno.onRetenoNotificationReceived.listen((event) {
      _showAlert(context, event.toString());
    });
  }

  final _formKey = GlobalKey<FormBuilderState>();

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
      appBar: AppBar(title: const Text('Reteno Example')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
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
                      initialValue: const {
                        'externalUserId': null,
                        'phone': null,
                        'email': null,
                        'first_name': null,
                        'last_name': null,
                        'language_code': null,
                        'timezone': null,
                        'region': null,
                        'town': null,
                        'address': null,
                        'postcode': null,
                        'group_include': null,
                        'group_exclude': null,
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
                          FormBuilderTextField(
                            name: 'externalUserId',
                            decoration: inputDecoration('External User Id'),
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                            ]),
                          ),
                          const SizedBox(height: 8),
                          FormBuilderTextField(
                            name: 'phone',
                            decoration: inputDecoration('Phone number'),
                          ),
                          const SizedBox(height: 8),
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
                          const SizedBox(height: 16),
                          FormBuilderTextField(
                            name: 'groups_exclude',
                            decoration: inputDecoration('Groups to exclude'),
                          ),
                          const SizedBox(height: 8),
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
                            decoration:
                                inputDecoration('Value for custom field TEXT'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                    final value = _formKey.currentState?.value;
                    if (value == null) {
                      return;
                    }
                    final customFields = <UserCustomField>[];
                    if (value['additional_info']?.toString().isNotEmpty ??
                        false) {
                      customFields.add(UserCustomField(
                          key: 'ADDITIONAL_FIELDS.TEXT',
                          value: value['additional_info']));
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

                    if ([
                          email,
                          firstName,
                          lastName,
                          phone,
                          timezone,
                          languageCode
                        ].any((element) =>
                            element != null && element.isNotEmpty) ||
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
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32),
                  child: Text(
                    'Update',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
