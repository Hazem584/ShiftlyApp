import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/attendance/data/attendance_repository.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';
import 'package:shiftly/features/notifications/data/notification_repository.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:shiftly/features/notifications/presentation/widgets/notification_presentation.dart';
import 'package:shiftly/features/shifts/data/shift_repository.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationsCubit>().load(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notifications'),
      actions: [
        BlocBuilder<NotificationsCubit, NotificationsState>(
          buildWhen: (previous, current) =>
              previous.unreadCount != current.unreadCount ||
              previous.markingAll != current.markingAll,
          builder: (context, state) => TextButton(
            key: const Key('mark-all-notifications-read'),
            onPressed: state.unreadCount == 0 || state.markingAll
                ? null
                : _markAll,
            child: state.markingAll
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Mark all read'),
          ),
        ),
      ],
    ),
    body: BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        if (state.initialLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.notifications.isEmpty && state.failure != null) {
          return EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load notifications',
            message: state.failure!.message,
            action: FilledButton(
              onPressed: context.read<NotificationsCubit>().load,
              child: const Text('Retry'),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () =>
              context.read<NotificationsCubit>().load(refresh: true),
          child: ListView(
            key: const Key('notifications-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              if (state.failure != null) ...[
                Text(
                  state.failure!.message,
                  style: const TextStyle(color: AppColors.error),
                ),
                const SizedBox(height: AppSpacing.s),
              ],
              if (state.notifications.isEmpty)
                const EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'No notifications',
                  message: 'Workspace updates will appear here.',
                )
              else
                for (final notification in state.notifications) ...[
                  _NotificationCard(
                    notification: notification,
                    timezone:
                        context.read<NotificationsCubit>().scope?.timezone ??
                        'Etc/UTC',
                    mutating:
                        state.markingIds.contains(notification.id) ||
                        state.deletingIds.contains(notification.id),
                    onOpen: () => _open(notification),
                    onDelete: () => _delete(notification),
                  ),
                  const SizedBox(height: 10),
                ],
              if (state.hasMore)
                OutlinedButton(
                  onPressed: state.loadingMore
                      ? null
                      : context.read<NotificationsCubit>().loadMore,
                  child: state.loadingMore
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Load more'),
                ),
            ],
          ),
        );
      },
    ),
  );

  Future<void> _open(NotificationRecord notification) async {
    final cubit = context.read<NotificationsCubit>();
    if (notification.isUnread) {
      final result = await cubit.markRead(notification.id);
      if (!mounted || result == NotificationMutationResult.stale) return;
      if (result == NotificationMutationResult.failure) {
        ToastService.error(
          context,
          message:
              cubit.state.failure?.message ??
              'Unable to open the notification.',
        );
        return;
      }
      if (result == NotificationMutationResult.busy) return;
    }
    if (!mounted) return;
    await _NotificationNavigator.open(context, cubit.scope, notification);
  }

  Future<void> _markAll() async {
    final cubit = context.read<NotificationsCubit>();
    final result = await cubit.markAllRead();
    if (!mounted || result == NotificationMutationResult.stale) return;
    if (result == NotificationMutationResult.success) {
      ToastService.success(context, message: 'All notifications marked read');
    } else if (result == NotificationMutationResult.failure) {
      ToastService.error(
        context,
        message:
            cubit.state.failure?.message ??
            'Unable to mark all notifications as read.',
      );
    }
  }

  Future<void> _delete(NotificationRecord notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete notification?'),
        content: const Text('This notification will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-delete-notification'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final cubit = context.read<NotificationsCubit>();
    final result = await cubit.delete(notification.id);
    if (!mounted || result == NotificationMutationResult.stale) return;
    if (result == NotificationMutationResult.success) {
      ToastService.success(context, message: 'Notification deleted');
    } else if (result == NotificationMutationResult.failure) {
      ToastService.error(
        context,
        message:
            cubit.state.failure?.message ??
            'Unable to delete the notification.',
      );
    }
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.timezone,
    required this.mutating,
    required this.onOpen,
    required this.onDelete,
  });

  final NotificationRecord notification;
  final String timezone;
  final bool mutating;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final presentation = notificationPresentation(notification.type);
    return Material(
      key: Key('notification-${notification.id}'),
      color: notification.isUnread ? AppColors.selected : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.l),
        side: const BorderSide(color: AppColors.borderColor),
      ),
      child: InkWell(
        onTap: mutating ? null : onOpen,
        borderRadius: BorderRadius.circular(AppRadii.l),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: presentation.color.withValues(alpha: .12),
                foregroundColor: presentation.color,
                child: Icon(presentation.icon, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isUnread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (notification.isUnread)
                          const DecoratedBox(
                            key: Key('unread-indicator'),
                            decoration: BoxDecoration(
                              color: AppColors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox.square(dimension: 8),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${presentation.label} · ${WorkspaceTime.dateTime(notification.createdAt, timezone)}',
                      style: const TextStyle(
                        color: AppColors.lighterGray,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: Key('delete-${notification.id}'),
                onPressed: mutating ? null : onDelete,
                tooltip: 'Delete notification',
                icon: mutating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline_rounded, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

abstract final class _NotificationNavigator {
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static Future<void> open(
    BuildContext context,
    FeatureSessionScope? scope,
    NotificationRecord notification,
  ) async {
    if (scope == null || notification.workspaceId != scope.workspaceId) {
      _unavailable(context);
      return;
    }
    final destination = _destination(scope, notification);
    if (destination == null) return;
    if (!_uuid.hasMatch(destination.id)) {
      _unavailable(context);
      return;
    }
    try {
      final valid = await _exists(context, scope, destination);
      if (!context.mounted || !valid) {
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
      router.go(destination.location);
    } catch (_) {
      if (context.mounted) _unavailable(context);
    }
  }

  static _Destination? _destination(
    FeatureSessionScope scope,
    NotificationRecord notification,
  ) {
    final data = notification.data;
    if (data == null || notification.type == NotificationType.unknown) {
      return null;
    }
    return switch (notification.type) {
      NotificationType.attendanceClockedIn ||
      NotificationType.attendanceClockedOut when scope.isManager =>
        _Destination(
          id: _id(data, 'attendanceId'),
          location: '/attendance',
          kind: _DestinationKind.managerAttendance,
        ),
      NotificationType.leaveRequestCreated when scope.isManager => _Destination(
        id: _id(data, 'leaveRequestId'),
        location: '/attendance?tab=leaveRequests',
        kind: _DestinationKind.managerLeave,
      ),
      NotificationType.shiftAssigned ||
      NotificationType.shiftUpdated ||
      NotificationType.shiftCancelled
          when scope.isEmployee &&
              _id(data, 'employeeMembershipId') == scope.membershipId =>
        _Destination(
          id: _id(data, 'shiftId'),
          location: '/employee?tab=shifts',
          kind: _DestinationKind.employeeShift,
        ),
      NotificationType.leaveRequestApproved ||
      NotificationType.leaveRequestRejected when scope.isEmployee =>
        _Destination(
          id: _id(data, 'leaveRequestId'),
          location: '/employee?tab=leave',
          kind: _DestinationKind.employeeLeave,
        ),
      _ => null,
    };
  }

  static Future<bool> _exists(
    BuildContext context,
    FeatureSessionScope scope,
    _Destination destination,
  ) async => switch (destination.kind) {
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
  managerAttendance,
  managerLeave,
  employeeShift,
  employeeLeave,
}

class _Destination {
  const _Destination({
    required this.id,
    required this.location,
    required this.kind,
  });
  final String id;
  final String location;
  final _DestinationKind kind;
}
