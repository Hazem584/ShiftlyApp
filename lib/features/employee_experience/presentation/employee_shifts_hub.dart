import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';

import 'employee_active_attendance_screen.dart';
import 'employee_schedule_view.dart';
import 'employee_shifts_hub_nav.dart';

class EmployeeShiftsHub extends StatelessWidget {
  const EmployeeShiftsHub({required this.timezone, super.key});
  final String timezone;

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
      EmployeeShiftsHubNav(timezone: timezone),
      BlocBuilder<FlexibleAttendanceCubit, FlexibleAttendanceState>(
        builder: (context, state) => state.current?.isOpen == true
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          EmployeeActiveAttendanceScreen(timezone: timezone),
                    ),
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
