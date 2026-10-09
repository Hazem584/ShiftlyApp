import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_record_api.dart';

class AttendancePage {
  const AttendancePage({required this.data, required this.pagination});
  final List<AttendanceRecordApi> data;
  final ApiPagination pagination;
}
