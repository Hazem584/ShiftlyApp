import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_cubit.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit.dart';

List<Employee> activeAttendanceEmployees(BuildContext context) {
  final employees = context.read<EmployeesCubit>().state;
  if (employees is! EmployeesLoaded) return const [];
  return employees.employees
      .where(
        (employee) =>
            employee.employmentStatus == EmploymentStatus.active &&
            employee.role == EmployeeRole.employee,
      )
      .toList(growable: false);
}

DateTimeRange? initialAttendanceDateRange(
  ManagerAttendanceState state,
  String timezone,
) {
  if (state.query.from == null || state.query.to == null) return null;
  return DateTimeRange(
    start: WorkspaceTime.inWorkspace(state.query.from!, timezone),
    end: WorkspaceTime.inWorkspace(state.query.to!, timezone),
  );
}

String formatAttendanceDateRangeLabel(
  BuildContext context,
  DateTimeRange? dates,
) {
  if (dates == null) return context.tr('Any date');
  return context.tr(
    '{value1}-{value2}-{value3} to {value4}-{value5}-{value6}',
    {
      'value1': (dates.start.year).toString(),
      'value2': (dates.start.month).toString(),
      'value3': (dates.start.day).toString(),
      'value4': (dates.end.year).toString(),
      'value5': (dates.end.month).toString(),
      'value6': (dates.end.day).toString(),
    },
  );
}

AttendanceQuery buildFilteredAttendanceQuery({
  required ManagerAttendanceState state,
  required String? employeeId,
  required DateTimeRange? dates,
  required String timezone,
}) => AttendanceQuery(
  employeeMembershipId: employeeId,
  reviewStatus: state.query.reviewStatus,
  from: dates == null
      ? null
      : WorkspaceTime.wallTimeToUtc(
          date: dates.start,
          hour: 0,
          minute: 0,
          timezoneName: timezone,
        ),
  to: dates == null
      ? null
      : WorkspaceTime.wallTimeToUtc(
          date: dates.end,
          hour: 23,
          minute: 59,
          timezoneName: timezone,
        ),
);
