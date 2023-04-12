class RetenoCustomEventParameter {
  RetenoCustomEventParameter(this.name, this.value);

  final String name;
  final String? value;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'value': value,
    };
  }
}
