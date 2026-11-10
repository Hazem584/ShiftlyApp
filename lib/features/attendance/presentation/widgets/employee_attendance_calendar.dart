import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/features/attendance/presentation/cubit/attendance_calendar_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_attendance_calendar_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_calendar_state.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_month_summary.dart';

class EmployeeAttendanceCalendar extends StatelessWidget {
  const EmployeeAttendanceCalendar({super.key});
  @override
  Widget build(BuildContext context) {
    final calendar = context.read<EmployeeAttendanceCalendarCubit>();
    return BlocProvider<AttendanceCalendarCubit>.value(
      value: calendar,
      child: RefreshIndicator(
        onRefresh: () => calendar.load(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: const [
            AttendanceMonthSummary(),
            SizedBox(height: 12),
            AttendanceCalendarStateView(editable: true),
          ],
        ),
      ),
    );
  }
}
