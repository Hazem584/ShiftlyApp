String currentUserRequiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) throw FormatException('Invalid $key');
  return value;
}

String? currentUserOptionalString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

DateTime currentUserRequiredDate(Map<String, Object?> json, String key) {
  final value = json[key];
  final parsed = value is String ? DateTime.tryParse(value) : null;
  if (parsed == null) throw FormatException('Invalid $key');
  return parsed.toUtc();
}

DateTime? currentUserOptionalDate(Object? value) {
  if (value == null) return null;
  final parsed = value is String ? DateTime.tryParse(value) : null;
  if (parsed == null) throw const FormatException('Invalid date');
  return parsed.toUtc();
}
