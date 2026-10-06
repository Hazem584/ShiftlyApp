import 'package:equatable/equatable.dart';
import 'package:shiftly/core/network/api_model_parser.dart';

part 'parts/fixed_shift_repository/attendance_classification.dart';
part 'parts/fixed_shift_repository/attendance_source.dart';
part 'parts/fixed_shift_repository/shift_template.dart';
part 'parts/fixed_shift_repository/shift_template_input.dart';
part 'parts/fixed_shift_repository/shift_template_page.dart';
part 'parts/fixed_shift_repository/work_pattern.dart';
part 'parts/fixed_shift_repository/work_pattern_history.dart';
part 'parts/fixed_shift_repository/eligible_shift_occurrence.dart';
part 'parts/fixed_shift_repository/template_eligibility.dart';
part 'parts/fixed_shift_repository/pending_clock_in.dart';
part 'parts/fixed_shift_repository/flexible_attendance.dart';
part 'parts/fixed_shift_repository/fixed_shift_repository.dart';

String _dateOnly(Map<String, Object?> json, String key) {
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

String _operationalDate(Map<String, Object?> json, String key) {
  final value = ApiModelParser.string(json, key);
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    return _dateOnly({key: value}, key);
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw FormatException('Invalid $key');
  return parsed.toUtc().toIso8601String().substring(0, 10);
}
