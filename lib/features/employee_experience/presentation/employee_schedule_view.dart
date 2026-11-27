import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/presentation/cubit/attendance_calendar_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_attendance_calendar_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';

import 'employee_schedule_content.dart';

class EmployeeScheduleView extends StatefulWidget {
  const EmployeeScheduleView({required this.timezone, this.now, super.key});
  final String timezone;
  final DateTime Function()? now;
  @override
  State<EmployeeScheduleView> createState() => _EmployeeScheduleViewState();
}

class _EmployeeScheduleViewState extends State<EmployeeScheduleView> {
  late int _week;
  Future<void> _move(int delta) async {
    final c = context.read<EmployeeAttendanceCalendarCubit>();
    final year = c.state.year ?? DateTime.now().year,
        month = c.state.month ?? DateTime.now().month;
    final count = (DateTime(year, month + 1, 0).day / 7).ceil();
    final next = _week + delta;
    if (next < 0) {
      setState(() => _week = (DateTime(year, month, 0).day - 1) ~/ 7);
      await c.previousMonth();
    } else if (next >= count) {
      setState(() => _week = 0);
      await c.nextMonth();
    } else {
      setState(() => _week = next);
    }
  }

  @override
  void initState() {
    super.initState();
    final current = WorkspaceTime.inWorkspace(
      widget.now?.call() ?? DateTime.now(),
      widget.timezone,
    );
    _week = (current.day - 1) ~/ 7;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<EmployeeAttendanceCalendarCubit>().open();
    });
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<EmployeeAttendanceCalendarCubit, AttendanceCalendarState>(
        builder: (context, calendar) =>
            BlocBuilder<FlexibleAttendanceCubit, FlexibleAttendanceState>(
              builder: (context, state) {
                final calendarCubit = context
                    .read<EmployeeAttendanceCalendarCubit>();
                return RefreshIndicator(
                  onRefresh: () => Future.wait([
                    calendarCubit.load(refresh: true),
                    context.read<FlexibleAttendanceCubit>().load(refresh: true),
                  ]),
                  child: EmployeeScheduleContent(
                    calendar: calendar,
                    state: state,
                    timezone: widget.timezone,
                    week: _week,
                    onMove: _move,
                    onRetry: () => calendarCubit.load(refresh: true),
                  ),
                );
              },
            ),
      );
}
