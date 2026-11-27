import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_dialog.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/missed_attendance_request_dialog.dart';

Future<void> requestMissedAttendanceReview(
  BuildContext context,
  EligibleShiftOccurrence entry,
  String workspaceId,
  String fallbackTimezone,
) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => MissedAttendanceRequestDialog(
      entry: entry,
      workspaceId: workspaceId,
      timezone: entry.timezone ?? fallbackTimezone,
      repository: getIt<TeamWorkRepository>(),
    ),
  );
  if (saved == true && context.mounted) {
    ToastService.success(
      context,
      message:
          'Request sent to your manager. Track it in Attendance corrections.',
    );
    context.read<FlexibleAttendanceCubit>().load(refresh: true);
  }
}

Future<void> confirmFlexibleClockOut(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => ManagerDialog(
      title: Text(context.tr('Clock out now?')),
      content: Text(
        context.tr(
          'Your final worked duration will be calculated by the server.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(context.tr('Stay clocked in')),
        ),
        FilledButton(
          key: const Key('confirm-flexible-clock-out'),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(context.tr('Clock out')),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final result = await context.read<FlexibleAttendanceCubit>().clockOut();
  if (context.mounted && result == FixedShiftMutationResult.success) {
    ToastService.success(context, message: 'Clock-out confirmed.');
  }
}
