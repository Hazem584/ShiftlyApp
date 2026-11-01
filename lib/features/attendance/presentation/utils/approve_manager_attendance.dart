import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_cubit.dart';
import 'package:shiftly/features/manager/presentation/widgets/manager_confirmation_sheet.dart';

/// Keeps the review owned by the record's current workspace while confirming.
Future<void> approveManagerAttendance(
  BuildContext context,
  BuildContext sheetContext,
  AttendanceRecordApi record,
  String timezone,
) async {
  final cubit = context.read<ManagerAttendanceCubit>();
  final owner = cubit.scope;
  final confirmed = await showManagerConfirmation(
    sheetContext,
    title: 'Approve attendance?',
    description:
        '${record.employee.displayName}\n${WorkspaceTime.dateTime(record.clockInAt, record.workspaceTimezone ?? timezone)}',
    action: 'Approve attendance',
    confirmKey: const Key('confirm-approve-attendance'),
  );
  if (!confirmed ||
      !context.mounted ||
      cubit.isClosed ||
      cubit.scope != owner) {
    return;
  }
  final result = await cubit.review(
    record.id,
    AttendanceReviewDecision.approved,
  );
  if (!context.mounted || !sheetContext.mounted || cubit.scope != owner) return;
  if (result == AttendanceMutationResult.success) {
    Navigator.pop(sheetContext);
    ToastService.success(context, message: 'Attendance approved.');
  }
}
