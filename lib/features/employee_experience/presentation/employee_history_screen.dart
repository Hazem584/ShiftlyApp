import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_attendance_calendar_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/employee_attendance_calendar.dart';
import 'package:shiftly/features/attendance/presentation/widgets/employee_attendance_history.dart';

import 'employee_page.dart';

class EmployeeHistoryScreen extends StatefulWidget {
  const EmployeeHistoryScreen({
    required this.timezone,
    this.calendar = false,
    super.key,
  });
  final String timezone;
  final bool calendar;
  @override
  State<EmployeeHistoryScreen> createState() => _EmployeeHistoryScreenState();
}

class _EmployeeHistoryScreenState extends State<EmployeeHistoryScreen> {
  late bool _calendar = widget.calendar;
  @override
  void initState() {
    super.initState();
    if (_calendar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<EmployeeAttendanceCalendarCubit>().open();
      });
    }
  }

  @override
  Widget build(BuildContext context) => EmployeePage(
    title: _calendar ? 'My calendar' : 'My history',
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(context.tr('List')),
                  icon: const Icon(Icons.list_alt_outlined),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(context.tr('Calendar')),
                  icon: const Icon(Icons.calendar_month_outlined),
                ),
              ],
              selected: {_calendar},
              onSelectionChanged: (v) {
                setState(() => _calendar = v.first);
                if (_calendar) {
                  context.read<EmployeeAttendanceCalendarCubit>().open();
                }
              },
            ),
          ),
        ),
        Expanded(
          child: _calendar
              ? const EmployeeAttendanceCalendar()
              : EmployeeAttendanceHistory(
                  timezone: widget.timezone,
                  includeControls: false,
                ),
        ),
      ],
    ),
  );
}
