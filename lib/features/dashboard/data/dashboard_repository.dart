import 'package:equatable/equatable.dart';
import 'package:shiftly/core/network/api_model_parser.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';
import 'package:shiftly/features/shifts/data/shift_repository.dart';

part 'parts/dashboard_repository/dashboard_data.dart';
part 'parts/dashboard_repository/manager_dashboard_data.dart';
part 'parts/dashboard_repository/manager_dashboard_summary.dart';
part 'parts/dashboard_repository/dashboard_person.dart';
part 'parts/dashboard_repository/dashboard_attendance_status.dart';
part 'parts/dashboard_repository/dashboard_attendance.dart';
part 'parts/dashboard_repository/dashboard_shift_preview.dart';
part 'parts/dashboard_repository/dashboard_leave_preview.dart';
part 'parts/dashboard_repository/employee_dashboard_data.dart';
part 'parts/dashboard_repository/employee_dashboard_identity.dart';
part 'parts/dashboard_repository/employee_dashboard_shift.dart';
part 'parts/dashboard_repository/employee_dashboard_summary.dart';
part 'parts/dashboard_repository/employee_dashboard_leave.dart';
part 'parts/dashboard_repository/dashboard_repository.dart';

String _uuid(Map<String, Object?> json, String key) {
  final value = ApiModelParser.string(json, key);
  if (!RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(value)) {
    throw FormatException('Invalid $key');
  }
  return value;
}

bool _boolean(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! bool) throw FormatException('Invalid $key');
  return value;
}

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
