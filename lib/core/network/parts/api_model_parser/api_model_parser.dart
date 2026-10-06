part of '../../api_model_parser.dart';

abstract final class ApiModelParser {
  static Map<String, Object?> map(Object? value, [String name = 'object']) {
    if (value is! Map) throw FormatException('Invalid $name');
    return Map<String, Object?>.from(value);
  }

  static Map<String, Object?>? optionalMap(
    Object? value, [
    String name = 'object',
  ]) {
    if (value == null) return null;
    return map(value, name);
  }

  static List<Object?> list(Object? value, [String name = 'list']) {
    if (value is! List) throw FormatException('Invalid $name');
    return value;
  }

  static String string(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Invalid $key');
    }
    return value;
  }

  static String? optionalString(Object? value) =>
      value is String && value.isNotEmpty ? value : null;

  static int integer(Map<String, Object?> json, String key, {int minimum = 0}) {
    final value = json[key];
    if (value is! int || value < minimum) throw FormatException('Invalid $key');
    return value;
  }

  static int? optionalInteger(Object? value, {int minimum = 0}) {
    if (value == null) return null;
    if (value is! int || value < minimum) {
      throw const FormatException('Invalid integer');
    }
    return value;
  }

  static DateTime date(Map<String, Object?> json, String key) {
    final value = optionalDate(json[key]);
    if (value == null) throw FormatException('Invalid $key');
    return value;
  }

  static DateTime? optionalDate(Object? value) {
    if (value == null) return null;
    final parsed = value is String ? DateTime.tryParse(value) : null;
    if (parsed == null) throw const FormatException('Invalid date');
    return parsed.toUtc();
  }
}
