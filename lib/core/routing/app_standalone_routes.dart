import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/device_sessions/presentation/device_sessions_screen.dart';
import 'package:shiftly/features/profile/domain/repositories/profile_image_picker.dart';
import 'package:shiftly/features/support/domain/support_repository.dart';
import 'package:shiftly/features/support/presentation/support_detail_screen.dart';
import 'package:shiftly/features/support/presentation/support_inbox_screen.dart';
import 'package:shiftly/features/support/presentation/support_session_boundary.dart';
import 'package:shiftly/features/tasks/presentation/tasks_screen.dart';
import 'package:shiftly/features/team_work/presentation/assigned_tasks_screen.dart';
import 'package:shiftly/features/team_work/presentation/team_work_screen.dart';

List<RouteBase> buildStandaloneAppRoutes(
  SessionCoordinator? sessionCoordinator,
) => [
  GoRoute(
    path: '/support',
    builder: (_, _) => SupportSessionBoundary(
      child: SupportInboxScreen(
        repository: getIt<SupportRepository>(),
        workspaceId:
            sessionCoordinator?.state.activeMembership?.workspace.id ?? '',
        picker: getIt<ProfileImagePicker>(),
      ),
    ),
  ),
  GoRoute(
    path: '/support/:ticketId',
    builder: (_, state) => SupportSessionBoundary(
      child: SupportDetailScreen(
        key: ValueKey(state.pathParameters['ticketId']),
        repository: getIt<SupportRepository>(),
        id: state.pathParameters['ticketId']!,
      ),
    ),
  ),
  GoRoute(
    path: '/attendance',
    redirect: (_, state) => state.uri.queryParameters['tab'] == 'calendar'
        ? '/employees?tab=calendar'
        : state.uri.queryParameters['tab'] == 'leaveRequests'
        ? '/employees?tab=leaveRequests'
        : '/employees?tab=attendance',
  ),
  GoRoute(
    path: '/attendance/reports',
    redirect: (_, _) => '/employees?tab=reports',
  ),
  GoRoute(
    path: '/devices',
    builder: (_, _) => DeviceSessionsScreen(
      onCurrentSessionRevoked: () async {
        await sessionCoordinator?.signOut();
      },
    ),
  ),
  GoRoute(
    path: '/tasks',
    builder: (_, state) =>
        TasksScreen(taskId: state.uri.queryParameters['taskId']),
  ),
  GoRoute(
    path: '/assigned-tasks',
    builder: (_, state) =>
        AssignedTasksScreen(taskId: state.uri.queryParameters['taskId']),
  ),
  GoRoute(
    path: '/team-work',
    builder: (_, state) => TeamWorkScreen(
      initialTab: state.uri.queryParameters['tab'] ?? 'announcements',
    ),
  ),
];
