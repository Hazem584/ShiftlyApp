export 'chat_storage_path.dart';

final RegExp chatModelsUuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);

String chatUuid(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || !chatModelsUuid.hasMatch(value)) {
    throw FormatException('Invalid $key');
  }
  return value;
}

String? chatOptionalUuid(Object? value) {
  if (value == null) return null;
  if (value is! String || !chatModelsUuid.hasMatch(value)) {
    throw const FormatException('Invalid UUID');
  }
  return value;
}

Map<String, Object?> chatMap(Object? value, [String label = 'object']) {
  if (value is! Map) throw FormatException('Invalid $label');
  return Map<String, Object?>.from(value);
}

List<Object?> chatList(Object? value, [String label = 'list']) {
  if (value is! List) throw FormatException('Invalid $label');
  return value;
}

String chatModelsText(
  Map<String, Object?> json,
  String key, {
  bool empty = false,
}) {
  final value = json[key];
  if (value is! String || (!empty && value.trim().isEmpty)) {
    throw FormatException('Invalid $key');
  }
  return value;
}

String? chatModelsOptionalText(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;

int chatModelsCount(Object? value, String label) {
  if (value is! int || value < 0) throw FormatException('Invalid $label');
  return value;
}

DateTime chatModelsDate(Map<String, Object?> json, String key) {
  final value = json[key];
  final date = value is String ? DateTime.tryParse(value) : null;
  if (date == null) throw FormatException('Invalid $key');
  return date.toUtc();
}

DateTime? chatModelsOptionalDate(Object? value) {
  if (value == null) return null;
  final date = value is String ? DateTime.tryParse(value) : null;
  if (date == null) throw const FormatException('Invalid timestamp');
  return date.toUtc();
}
