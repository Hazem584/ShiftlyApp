import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/attendance/presentation/widgets/employee_leave_requests_panel.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';

import 'employee_active_attendance_screen.dart';
import 'employee_history_screen.dart';
import 'employee_page.dart';
import 'employee_schedule_view.dart';

class EmployeeShiftsHub extends StatelessWidget {
  const EmployeeShiftsHub({required this.timezone, super.key});
  final String timezone;
  void _open(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        child: Text(
          context.tr('My Shifts'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      SizedBox(
        height: 52,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          scrollDirection: Axis.horizontal,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Chip(label: Text(context.tr('Schedule'))),
            ),
            TextButton(
              onPressed: () =>
                  _open(context, EmployeeHistoryScreen(timezone: timezone)),
              child: Text(context.tr('My history')),
            ),
            TextButton(
              onPressed: () => _open(
                context,
                EmployeeHistoryScreen(timezone: timezone, calendar: true),
              ),
              child: Text(context.tr('My calendar')),
            ),
            TextButton(
              key: const Key('employee-leave-link'),
              onPressed: () => _open(
                context,
                EmployeePage(
                  title: 'My requests',
                  child: EmployeeLeaveRequestsPanel(timezone: timezone),
                ),
              ),
              child: Text(context.tr('Leave')),
            ),
            TextButton(
              onPressed: () => context.push('/team-work?tab=corrections'),
              child: Text(context.tr('My corrections')),
            ),
          ],
        ),
      ),
      BlocBuilder<FlexibleAttendanceCubit, FlexibleAttendanceState>(
        builder: (context, state) => state.current?.isOpen == true
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextButton.icon(
                  onPressed: () => _open(
                    context,
                    EmployeeActiveAttendanceScreen(timezone: timezone),
                  ),
                  icon: const Icon(Icons.schedule_outlined),
                  label: Text(context.tr('View active attendance')),
                ),
              )
            : const SizedBox.shrink(),
      ),
      Expanded(child: EmployeeScheduleView(timezone: timezone)),
    ],
  );
}
