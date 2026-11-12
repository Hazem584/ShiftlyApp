import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/breaks/application/shift_break_controller.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';

Future<bool> confirmEmployeeAction(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  String? actionKey,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(c.tr(title)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(c.tr('Cancel')),
          ),
          FilledButton(
            key: actionKey == null ? null : Key(actionKey),
            onPressed: () => Navigator.pop(c, true),
            child: Text(c.tr(action)),
          ),
        ],
      ),
    ) ==
    true;

Future<void> employeeClockOut(BuildContext context) async {
  final cubit = context.read<FlexibleAttendanceCubit>();
  final id = cubit.state.current?.id;
  if (id == null ||
      cubit.busy ||
      cubit.state.recoveryBlocked ||
      cubit.state.failure != null) {
    return;
  }
  final confirmed = await confirmEmployeeAction(
    context,
    title: 'Finish your shift?',
    message: context.tr(
      'Your final worked duration will be calculated by the server.',
    ),
    action: 'Confirm check-out',
    actionKey: 'confirm-employee-clock-out',
  );
  if (!confirmed || !context.mounted || cubit.state.current?.id != id) return;
  final result = await cubit.clockOut();
  if (!context.mounted) return;
  if (result == FixedShiftMutationResult.success) {
    await context.read<ShiftBreakController?>()?.finish();
  }
  if (!context.mounted) return;
  if (result != FixedShiftMutationResult.success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr('Could not clock out. Check your attendance and retry.'),
        ),
      ),
    );
  }
}
