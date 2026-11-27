import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/widgets/confirm_action.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/eligible_shift_occurrence.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';

import 'employee_active_attendance_screen.dart';
import 'employee_page.dart';
import 'employee_shift_details_body.dart';
import 'employee_shift_details_footer.dart';
import 'employee_shift_status_eval.dart';

class EmployeeShiftDetailsScreen extends StatelessWidget {
  const EmployeeShiftDetailsScreen({
    required this.entry,
    required this.timezone,
    super.key,
  });

  final EligibleShiftOccurrence entry;
  final String timezone;

  Future<void> _checkIn(
    BuildContext context,
    EligibleShiftOccurrence value,
  ) async {
    final cubit = context.read<FlexibleAttendanceCubit>();
    final confirmed = await confirmAction(
      context,
      title: 'Start your shift?',
      message: '${value.template.name} · ${value.operationalDate} · $timezone',
      action: 'Confirm check-in',
      actionKey: 'confirm-flexible-clock-in',
    );
    if (!confirmed || !context.mounted) return;
    final result = await cubit.clockIn(value);
    if (context.mounted && result == FixedShiftMutationResult.success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => EmployeeActiveAttendanceScreen(timezone: timezone),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<FlexibleAttendanceCubit, FlexibleAttendanceState>(
        builder: (context, state) {
          final eval = EmployeeShiftStatusEval(state, entry);
          return EmployeePage(
            title: 'Shift details',
            footer: EmployeeShiftDetailsFooter(
              eval: eval,
              timezone: timezone,
              onCheckIn: (value) => _checkIn(context, value),
            ),
            child: EmployeeShiftDetailsBody(eval: eval, timezone: timezone),
          );
        },
      );
}
