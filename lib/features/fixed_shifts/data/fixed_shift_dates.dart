import 'package:shiftly/core/network/api_model_parser.dart';

String fixedShiftDateOnly(Map<String, Object?> json, String key) {
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

String fixedShiftOperationalDate(Map<String, Object?> json, String key) {
  final value = ApiModelParser.string(json, key);
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    return fixedShiftDateOnly({key: value}, key);
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException('Invalid $key');
  }
  return parsed.toUtc().toIso8601String().substring(0, 10);
}
