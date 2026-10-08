class ManagerFormField {
  const ManagerFormField(
    this.key,
    this.label, {
    this.minimum,
    this.maximum,
    this.choices,
    this.initial,
    this.boolean = false,
    this.date = false,
    this.help,
  });
  final String key, label;
  final int? minimum, maximum;
  final List<String>? choices;
  final Object? initial;
  final bool boolean, date;
  final String? help;
}
