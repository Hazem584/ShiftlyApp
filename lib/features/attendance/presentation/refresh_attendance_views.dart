import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/features/attendance/presentation/cubit/attendance_calendar_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_attendance_calendar_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_attendance_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_cubit.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/reports/presentation/attendance_reports_cubit.dart';

void refreshAttendanceViews(BuildContext context) {
  final calendar = context.read<AttendanceCalendarCubit?>();
  final employeeCalendar = context.read<EmployeeAttendanceCalendarCubit?>();
  calendar?.invalidate();
  if (!identical(calendar, employeeCalendar)) employeeCalendar?.invalidate();
  final employee = context.read<EmployeeAttendanceCubit?>();
  if (employee != null) unawaited(employee.load(refresh: true));
  context.read<AttendanceReportsCubit?>()?.invalidate();
  context.read<DashboardCubit?>()?.invalidate();
  final attendance = context.read<ManagerAttendanceCubit?>();
  if (attendance != null) unawaited(attendance.load(refresh: true));
}
