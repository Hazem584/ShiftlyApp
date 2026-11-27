import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/notifications/presentation/utils/notification_destination.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

Future<bool> verifyNotificationDestinationExists(
  BuildContext context,
  FeatureSessionScope scope,
  NotificationDestination destination,
) async => switch (destination.kind) {
  NotificationDestinationKind.teamWork ||
  NotificationDestinationKind.support => true,
  NotificationDestinationKind.chatGroup => () async {
    final group = await context.read<ChatRepository>().getGroup(
      scope.workspaceId,
      destination.id,
    );
    return group.id == destination.id &&
        group.workspaceId == scope.workspaceId &&
        !group.isArchived;
  }(),
  NotificationDestinationKind.managerAttendance => () async {
    final record = await context
        .read<AttendanceRepository>()
        .getWorkspaceAttendance(scope.workspaceId, destination.id);
    return record.id == destination.id &&
        record.workspaceId == scope.workspaceId;
  }(),
  NotificationDestinationKind.managerLeave => () async {
    final record = await context.read<LeaveRequestRepository>().getWorkspace(
      scope.workspaceId,
      destination.id,
    );
    return record.id == destination.id &&
        record.workspaceId == scope.workspaceId;
  }(),
  NotificationDestinationKind.employeeShift => () async {
    final record = await context.read<ShiftRepository>().getMyShift(
      destination.id,
    );
    return record.id == destination.id &&
        record.workspaceId == scope.workspaceId &&
        record.employeeMembershipId == scope.membershipId;
  }(),
  NotificationDestinationKind.employeeLeave => () async {
    final record = await context.read<LeaveRequestRepository>().getMine(
      destination.id,
    );
    return record.id == destination.id &&
        record.workspaceId == scope.workspaceId &&
        record.employeeMembershipId == scope.membershipId;
  }(),
};
