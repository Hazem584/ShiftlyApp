import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';

Future<DateTime?> pickLeaveRequestDate({
  required BuildContext context,
  required String timezone,
  required DateTime initialDate,
}) {
  final workspaceNow = WorkspaceTime.inWorkspace(
    DateTime.now().toUtc(),
    timezone,
  );
  final firstDate = DateTime(
    workspaceNow.year,
    workspaceNow.month,
    workspaceNow.day,
  );
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: firstDate.add(const Duration(days: 365)),
  );
}

Future<void> submitLeaveRequestForm({
  required BuildContext context,
  required LeaveRequestType type,
  required DateTime startDate,
  required DateTime endDate,
  required TimeOfDay startTime,
  required TimeOfDay endTime,
  required String timezone,
  required String reason,
}) async {
  final early = type == LeaveRequestType.earlyLeave;
  final startsAt = WorkspaceTime.wallTimeToUtc(
    date: startDate,
    hour: early ? startTime.hour : 0,
    minute: early ? startTime.minute : 0,
    timezoneName: timezone,
  );
  final endsAt = WorkspaceTime.wallTimeToUtc(
    date: early ? startDate : endDate,
    hour: early ? endTime.hour : 23,
    minute: early ? endTime.minute : 59,
    timezoneName: timezone,
  );
  final cubit = context.read<EmployeeLeaveRequestsCubit>();
  final result = await cubit.create(
    CreateLeaveRequestInput(
      type: type,
      startsAt: startsAt,
      endsAt: endsAt,
      reason: reason,
    ),
  );
  if (!context.mounted || result == LeaveMutationResult.stale) return;
  if (result == LeaveMutationResult.success) {
    ToastService.success(context, message: 'Leave request submitted');
    Navigator.pop(context);
  } else if (result == LeaveMutationResult.failure) {
    ToastService.error(
      context,
      message: cubit.state.failure?.message ?? 'Could not submit request',
    );
  }
}
