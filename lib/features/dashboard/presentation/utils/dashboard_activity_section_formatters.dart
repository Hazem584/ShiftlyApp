import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';

String dashboardActivitySectionAttendanceLabel(
  DashboardAttendance? attendance,
) => switch (attendance?.status) {
  DashboardAttendanceStatus.clockedIn => 'Clocked in',
  DashboardAttendanceStatus.completed => 'Completed',
  DashboardAttendanceStatus.unknown => 'Recorded',
  null => 'Scheduled',
};
