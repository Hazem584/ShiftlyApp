import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:shiftly/features/tasks/application/tasks_cubit.dart';

abstract final class NotificationsScreenNotificationNavigator {
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static Future<void> open(
    BuildContext context,
    FeatureSessionScope? scope,
    NotificationRecord notification,
  ) async {
    if (notification.type == NotificationType.taskReminder && scope != null) {
      final id = notification.data?['taskId'];
      if (id is! String || !_uuid.hasMatch(id)) {
        _unavailable(context);
        return;
      }
      final cubit = context.read<TasksCubit>();
      final task = await cubit.resolveTap(scope.userId, id);
      if (!context.mounted) return;
      if (task == null || cubit.scope != scope) {
        _unavailable(context);
        return;
      }
      GoRouter.of(context).push('/tasks?taskId=${task.id}');
      return;
    }
    if (scope == null || notification.workspaceId != scope.workspaceId) {
      _unavailable(context);
      return;
    }
    final notifications = context.read<NotificationsCubit>();
    if (notifications.scope != scope) {
      _unavailable(context);
      return;
    }
    final destination = _destination(scope, notification);
    if (destination == null) {
      if ({
        NotificationType.shiftAssigned,
        NotificationType.shiftUpdated,
        NotificationType.shiftCancelled,
        NotificationType.shiftReminder,
      }.contains(notification.type)) {
        _unavailable(context);
      }
      return;
    }
    if (!_uuid.hasMatch(destination.id)) {
      _unavailable(context);
      return;
    }
    try {
      final valid = await _exists(context, scope, destination);
      if (!context.mounted || !valid || notifications.scope != scope) {
        if (context.mounted) _unavailable(context);
        return;
      }
      final router = GoRouter.of(context);
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        final route = ModalRoute.of(context);
        navigator.pop();
        await route?.completed;
      }
      if (notifications.scope == scope) {
        router.go(destination.location);
      }
    } catch (_) {
      if (context.mounted) _unavailable(context);
    }
  }

  static _NotificationDestination? _destination(
    FeatureSessionScope scope,
    NotificationRecord notification,
  ) {
    final data = notification.data;
    if (data == null || notification.type == NotificationType.unknown) {
      return null;
    }
    return switch (notification.type) {
      NotificationType.shiftExchangeRequested ||
      NotificationType.shiftExchangeUpdated => _NotificationDestination(
        id: _id(data, 'exchangeId'),
        location: '/shift-exchanges',
        kind: _DestinationKind.teamWork,
      ),
      NotificationType.fixedShiftReminder when scope.isEmployee =>
        _NotificationDestination(
          id: _id(data, 'assignmentId'),
          location: '/employee?tab=shifts',
          kind: _DestinationKind.teamWork,
        ),
      NotificationType.clockOutReminder when scope.isEmployee =>
        _NotificationDestination(
          id: _id(data, 'attendanceId'),
          location: '/employee?tab=shifts',
          kind: _DestinationKind.teamWork,
        ),
      NotificationType.teamAnnouncement => _NotificationDestination(
        id: _id(data, 'announcementId'),
        location: '/team-work?tab=announcements',
        kind: _DestinationKind.teamWork,
      ),
      NotificationType.attendanceCorrectionCreated ||
      NotificationType.attendanceCorrectionReviewed => _NotificationDestination(
        id: _id(data, 'correctionId'),
        location: '/team-work?tab=corrections',
        kind: _DestinationKind.teamWork,
      ),
      NotificationType.attendanceClockedIn ||
      NotificationType.attendanceClockedOut when scope.isManager =>
        _NotificationDestination(
          id: _id(data, 'attendanceId'),
          location: '/attendance',
          kind: _DestinationKind.managerAttendance,
        ),
      NotificationType.leaveRequestCreated when scope.isManager =>
        _NotificationDestination(
          id: _id(data, 'leaveRequestId'),
          location: '/attendance?tab=leaveRequests',
          kind: _DestinationKind.managerLeave,
        ),
      NotificationType.shiftAssigned ||
      NotificationType.shiftUpdated ||
      NotificationType.shiftCancelled ||
      NotificationType.shiftReminder
          when scope.isEmployee &&
              _id(data, 'employeeMembershipId') == scope.membershipId =>
        _NotificationDestination(
          id: _id(data, 'shiftId'),
          location: '/employee?tab=shifts',
          kind: _DestinationKind.employeeShift,
        ),
      NotificationType.leaveRequestApproved ||
      NotificationType.leaveRequestRejected when scope.isEmployee =>
        _NotificationDestination(
          id: _id(data, 'leaveRequestId'),
          location: '/employee?tab=leave',
          kind: _DestinationKind.employeeLeave,
        ),
      NotificationType.chatMessage => _NotificationDestination(
        id: _id(data, 'groupId'),
        location: scope.isManager
            ? '/chat/${_id(data, 'groupId')}'
            : '/employee/chat/${_id(data, 'groupId')}',
        kind: _DestinationKind.chatGroup,
      ),
      _ => null,
    };
  }

  static Future<bool> _exists(
    BuildContext context,
    FeatureSessionScope scope,
    _NotificationDestination destination,
  ) async => switch (destination.kind) {
    _DestinationKind.teamWork => true,
    _DestinationKind.chatGroup => () async {
      final group = await context.read<ChatRepository>().getGroup(
        scope.workspaceId,
        destination.id,
      );
      return group.id == destination.id &&
          group.workspaceId == scope.workspaceId &&
          !group.isArchived;
    }(),
    _DestinationKind.managerAttendance => () async {
      final record = await context
          .read<AttendanceRepository>()
          .getWorkspaceAttendance(scope.workspaceId, destination.id);
      return record.id == destination.id &&
          record.workspaceId == scope.workspaceId;
    }(),
    _DestinationKind.managerLeave => () async {
      final record = await context.read<LeaveRequestRepository>().getWorkspace(
        scope.workspaceId,
        destination.id,
      );
      return record.id == destination.id &&
          record.workspaceId == scope.workspaceId;
    }(),
    _DestinationKind.employeeShift => () async {
      final record = await context.read<ShiftRepository>().getMyShift(
        destination.id,
      );
      return record.id == destination.id &&
          record.workspaceId == scope.workspaceId &&
          record.employeeMembershipId == scope.membershipId;
    }(),
    _DestinationKind.employeeLeave => () async {
      final record = await context.read<LeaveRequestRepository>().getMine(
        destination.id,
      );
      return record.id == destination.id &&
          record.workspaceId == scope.workspaceId &&
          record.employeeMembershipId == scope.membershipId;
    }(),
  };

  static String _id(Map<String, Object?> data, String key) =>
      data[key] is String ? data[key]! as String : '';

  static void _unavailable(BuildContext context) => ToastService.warning(
    context,
    message: 'This notification destination is no longer available.',
  );
}

enum _DestinationKind {
  teamWork,
  chatGroup,
  managerAttendance,
  managerLeave,
  employeeShift,
  employeeLeave,
}

class _NotificationDestination {
  const _NotificationDestination({
    required this.id,
    required this.location,
    required this.kind,
  });
  final String id;
  final String location;
  final _DestinationKind kind;
}
