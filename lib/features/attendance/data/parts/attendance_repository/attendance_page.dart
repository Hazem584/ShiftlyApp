part of '../../attendance_repository.dart';

class AttendancePage {
  const AttendancePage({required this.data, required this.pagination});
  final List<AttendanceRecordApi> data;
  final ApiPagination pagination;
}
