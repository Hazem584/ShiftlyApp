import 'package:shiftly/core/serialization/api_model_parser.dart';

String dashboardModelsUuid(Map<String, Object?> json, String key) {
  final value = ApiModelParser.string(json, key);
  if (!RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(value)) {
    throw FormatException('Invalid $key');
  }
  return value;
}

bool dashboardModelsBoolean(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! bool) throw FormatException('Invalid $key');
  return value;
}

String dashboardModelsDateOnly(Map<String, Object?> json, String key) {
  final value = ApiModelParser.string(json, key);
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) {
    throw FormatException('Invalid $key');
  }
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final parsed = DateTime.utc(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    throw FormatException('Invalid $key');
  }
  return value;
}
