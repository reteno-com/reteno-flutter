class RetenoCustomEventParameter {
  RetenoCustomEventParameter(this.name, this.value);

  final String name;
  final String? value;

  // CustomEventParameter toCustomEventParameter() {
  //   return CustomEventParameter(
  //     name: name,
  //     value: value,
  //   );
  // }

  @override
  String toString() {
    return 'RetenoCustomEventParameter{name: $name, value: $value}';
  }
}
