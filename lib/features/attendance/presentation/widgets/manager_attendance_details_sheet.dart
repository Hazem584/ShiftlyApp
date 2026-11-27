import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_rejection_dialog.dart';
import 'package:shiftly/features/attendance/presentation/widgets/manager_attendance_record_info.dart';

Future<void> showManagerAttendanceDetails(
  BuildContext context,
  String attendanceId,
  String timezone,
) async {
  final record = await context.read<ManagerAttendanceCubit>().loadDetails(
    attendanceId,
  );
  if (record == null || !context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...buildManagerAttendanceRecordInfo(context, record, timezone),
              if (record.canReview) ...[
                const SizedBox(height: AppSpacing.l),
                FilledButton.icon(
                  key: const Key('approve-attendance'),
                  onPressed: () => _approve(context, sheetContext, record.id),
                  icon: const Icon(Icons.check_rounded),
                  label: Text(context.tr('Approve')),
                ),
                const SizedBox(height: AppSpacing.s),
                OutlinedButton.icon(
                  key: const Key('reject-attendance'),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _reject(context, record.id);
                  },
                  icon: const Icon(Icons.close_rounded),
                  label: Text(context.tr('Reject')),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _approve(
  BuildContext context,
  BuildContext sheetContext,
  String recordId,
) async {
  final result = await context.read<ManagerAttendanceCubit>().review(
    recordId,
    AttendanceReviewDecision.approved,
  );
  if (!context.mounted) return;
  if (result == AttendanceMutationResult.success) {
    Navigator.pop(sheetContext);
    ToastService.success(context, message: 'Attendance approved.');
  }
}

Future<void> _reject(BuildContext context, String attendanceId) async {
  final cubit = context.read<ManagerAttendanceCubit>();
  final rejected = await showDialog<bool>(
    context: context,
    builder: (_) =>
        AttendanceRejectionDialog(cubit: cubit, attendanceId: attendanceId),
  );
  if (context.mounted && rejected == true) {
    ToastService.success(context, message: 'Attendance rejected.');
  }
}
