// ignore_for_file: must_be_immutable, no_logic_in_create_state

import 'package:flutter/material.dart';

class TempParameterModel {
  TempParameterModel(this.id, this.name, this.value);
  final String name;
  final String value;
  final int id;

  TempParameterModel copyWith({String? name, String? value}) {
    return TempParameterModel(
      id,
      name ?? this.name,
      value ?? this.value,
    );
  }
}

class EventParameterForm extends StatefulWidget {
  EventParameterForm({
    super.key,
    required this.contactModel,
    required this.onRemove,
  });

  TempParameterModel contactModel;
  final Function onRemove;
  final state = _EventParameterFormState();

  @override
  State<StatefulWidget> createState() {
    return state;
  }

  bool isValidated() => state.validate();
}

class _EventParameterFormState extends State<EventParameterForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _valueContoller = TextEditingController();

  final formKey = GlobalKey<FormState>();
  inputDecoration(String labelText) => InputDecoration(
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
    return Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nameController,
                  onChanged: (value) => widget.contactModel =
                      widget.contactModel.copyWith(name: value),
                  onSaved: (value) => widget.contactModel =
                      widget.contactModel.copyWith(name: value),
                  validator: (value) =>
                      (value?.isNotEmpty ?? false) ? null : "Enter Name",
                  decoration: inputDecoration('Parameter name'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _valueContoller,
                  onChanged: (value) => widget.contactModel =
                      widget.contactModel.copyWith(value: value),
                  onSaved: (value) => widget.contactModel =
                      widget.contactModel.copyWith(value: value),
                  decoration: inputDecoration('Parameter value'),
                ),
              ),
              IconButton(
                onPressed: () {
                  widget.onRemove();
                },
                icon: const Icon(Icons.remove),
              )
            ],
          ),
        ));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueContoller.dispose();
    super.dispose();
  }

  bool validate() {
    //Validate Form Fields
    formKey.currentState?.save();
    bool validate = formKey.currentState?.validate() ?? false;

    return validate;
  }
}
