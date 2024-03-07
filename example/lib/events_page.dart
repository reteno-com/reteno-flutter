import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:reteno_plugin/reteno.dart';
import 'package:reteno_plugin_example/event_parameter_form.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final ValueNotifier<bool> _forcePush = ValueNotifier<bool>(false);

  final Reteno _reteno = Reteno();
  String eventTypeName = '';
  final TextEditingController _eventTypeController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  List<EventParameterForm> contactForms = List.empty(growable: true);

  InputDecoration inputDecoration(String labelText) => InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Colors.lightBlue,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
      );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Events'),
        centerTitle: false,
        actions: [
          Row(
            children: [
              const Text('Force push? '),
              ValueListenableBuilder(
                valueListenable: _forcePush,
                builder: (context, value, _) {
                  return Switch(
                    value: value,
                    onChanged: (value) {
                      _forcePush.value = value;
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SizedBox(height: 8),
                        const Text(
                          'Custom event:',
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            backgroundColor: Colors.amber,
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Form(
                          key: formKey,
                          child: TextFormField(
                            controller: _eventTypeController,
                            onChanged: (value) => eventTypeName = value,
                            onSaved: (value) => eventTypeName = value ?? '',
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                            ]),
                            decoration: inputDecoration('Event Type Key'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Custom parameters',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            backgroundColor: Colors.amber,
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: onAdd,
                          child: const Text(
                            'Add new parameter',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...contactForms,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    formKey.currentState?.save();
                  } else {
                    return;
                  }

                  bool allValid = true;

                  for (var element in contactForms) {
                    allValid = (allValid && element.isValidated());
                  }

                  if (allValid) {
                    for (var e in contactForms) {
                      debugPrint(
                          "${e.contactModel.name} : ${e.contactModel.value}");
                    }
                  } else {
                    debugPrint("Form is Not Valid");
                    return;
                  }

                  final dateOccured = DateTime.now();
                  final event = RetenoCustomEvent(
                    eventTypeKey: eventTypeName,
                    dateOccurred: dateOccured,
                    parameters: contactForms
                        .map((e) => RetenoCustomEventParameter(
                              e.contactModel.name,
                              e.contactModel.value,
                            ))
                        .toList(),
                    forcePush: _forcePush.value,
                  );
                  debugPrint(event.toString());

                  await _reteno.logEvent(event: event);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32),
                  child: Text(
                    'Send custom event',
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

  //Delete specific form
  onRemove(TempParameterModel contact) {
    setState(() {
      contactForms
          .removeWhere((element) => element.contactModel.id == contact.id);
    });
  }

  int counter = 0;
  onAdd() {
    setState(() {
      counter++;
      TempParameterModel contactModel = TempParameterModel(counter, '', '');
      contactForms.add(EventParameterForm(
        key: UniqueKey(),
        contactModel: contactModel,
        onRemove: () => onRemove(contactModel),
      ));
    });
  }

  @override
  void dispose() {
    super.dispose();
    _eventTypeController.dispose();
  }
}
