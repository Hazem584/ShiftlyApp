import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/network/api_model_parser.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/notifications/data/notification_repository.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:shiftly/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:shiftly/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:shiftly/features/shifts/data/shift_repository.dart';

const _workspaceId = 'c551356a-e456-4a3e-a49a-9dd0caa7e790';
const _notificationId = 'a5e624e8-ee45-4417-a932-5b48ad019656';
const _leaveId = 'f65933d1-57ce-4f70-a28e-574bea205344';
const _managerScope = FeatureSessionScope(
  userId: 'user',
  workspaceId: _workspaceId,
  membershipId: '15147f4c-bdca-4a81-a631-fd2253aeb1b8',
  timezone: 'Africa/Cairo',
  role: WorkspaceRole.manager,
);
const _employeeScope = FeatureSessionScope(
  userId: 'user',
  workspaceId: _workspaceId,
  membershipId: '040e52de-05b9-46b8-80ca-e7df3ef7444b',
  timezone: 'Africa/Cairo',
  role: WorkspaceRole.employee,
);

NotificationRecord _notification({
  NotificationType type = NotificationType.unknown,
  String id = _notificationId,
  String title =
      'A notification with a deliberately long title that wraps safely',
  String message = 'A long message that remains readable on a compact mobile screen without exposing any raw JSON payload.',
  Map<String, Object?>? data,
  DateTime? readAt,
  String workspaceId = _workspaceId,
}) => NotificationRecord(
  id: id,
  workspaceId: workspaceId,
  type: type,
  title: title,
  message: message,
  data: data,
  readAt: readAt,
  createdAt: DateTime.utc(2026, 9, 28, 8),
  updatedAt: DateTime.utc(2026, 9, 28, 8),
);

class _NotificationFake implements NotificationRepository {
  _NotificationFake({
    List<NotificationRecord>? records,
    this.count = 1,
    this.error,
  }) : records = records ?? [_notification()];
  List<NotificationRecord> records;
  int count;
  Object? error;
  int listCalls = 0;

  @override
  Future<NotificationPage> list(
    String workspaceId,
    NotificationQuery query,
  ) async {
    listCalls += 1;
    if (error != null) throw error!;
    return NotificationPage(
      data: List.of(records),
      pagination: ApiPagination(
        page: query.page,
        limit: query.limit,
        total: records.length,
        totalPages: records.isEmpty ? 0 : 1,
      ),
    );
  }

  @override
  Future<int> unreadCount() async {
    if (error != null) throw error!;
    return count;
  }

  @override
  Future<NotificationRecord> markRead(String notificationId) async {
    final index = records.indexWhere((item) => item.id == notificationId);
    final current = records[index];
    final updated = _copy(current, readAt: DateTime.utc(2026, 9, 28, 9));
    records[index] = updated;
    count = records.where((item) => item.isUnread).length;
    return updated;
  }

  @override
  Future<int> markAllRead(String workspaceId) async {
    final unread = records.where((item) => item.isUnread).length;
    records = records
        .map((item) => _copy(item, readAt: DateTime.utc(2026, 9, 28, 9)))
        .toList();
    count = 0;
    return unread;
  }

  @override
  Future<bool> delete(String notificationId) async {
    records.removeWhere((item) => item.id == notificationId);
    count = records.where((item) => item.isUnread).length;
    return true;
  }
}

NotificationRecord _copy(
  NotificationRecord value, {
  required DateTime readAt,
}) => NotificationRecord(
  id: value.id,
  workspaceId: value.workspaceId,
  type: value.type,
  title: value.title,
  message: value.message,
  data: value.data,
  readAt: readAt,
  createdAt: value.createdAt,
  updatedAt: readAt,
);

NotificationsCubit _cubit(
  _NotificationFake repository,
  FeatureSessionScope scope,
) => NotificationsCubit(repository)..bindSession(scope);

void main() {
  testWidgets('badge hides at zero and caps large counts at 99+', (
    tester,
  ) async {
    final repository = _NotificationFake(count: 120);
    final cubit = _cubit(repository, _managerScope);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const Scaffold(body: NotificationBell()),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('99+'), findsOneWidget);
    repository.count = 0;
    await cubit.refreshUnreadCount();
    expect(cubit.state.unreadCount, 0);
    await tester.pumpAndSettle();
    final badge = tester.widget<Badge>(
      find.byKey(const Key('notification-badge')),
    );
    expect(badge.isLabelVisible, isFalse);
  });

  testWidgets(
    'unknown notification is readable, marks read, does not navigate, and deletes after confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _NotificationFake();
      final cubit = _cubit(repository, _managerScope);
      addTearDown(cubit.close);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cubit,
            child: const NotificationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('unread-indicator')), findsOneWidget);
      expect(find.textContaining('deliberately long title'), findsOneWidget);
      await tester.tap(find.byKey(const Key('notification-$_notificationId')));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsScreen), findsOneWidget);
      expect(find.byKey(const Key('unread-indicator')), findsNothing);
      await tester.tap(find.byKey(const Key('delete-$_notificationId')));
      await tester.pumpAndSettle();
      expect(find.text('Delete notification?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm-delete-notification')));
      await tester.pumpAndSettle();
      expect(find.text('No notifications'), findsOneWidget);
      ToastService.dismissAll();
    },
  );

  testWidgets('mark all read refreshes canonical rows', (tester) async {
    final repository = _NotificationFake(
      records: [
        _notification(),
        _notification(id: 'b5e624e8-ee45-4417-a932-5b48ad019657'),
      ],
      count: 2,
    );
    final cubit = _cubit(repository, _employeeScope);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const NotificationsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('unread-indicator')), findsNWidgets(2));
    await tester.tap(find.byKey(const Key('mark-all-notifications-read')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('unread-indicator')), findsNothing);
    expect(cubit.state.unreadCount, 0);
    ToastService.dismissAll();
  });

  testWidgets('pull to refresh reloads the canonical list', (tester) async {
    final repository = _NotificationFake();
    final cubit = _cubit(repository, _managerScope);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const NotificationsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final callsBeforeRefresh = repository.listCalls;
    await tester.drag(
      find.byKey(const Key('notifications-list')),
      const Offset(0, 400),
    );
    await tester.pumpAndSettle();
    expect(repository.listCalls, callsBeforeRefresh + 1);
  });

  testWidgets('full failure shows retry and empty state renders safely', (
    tester,
  ) async {
    final failedRepository = _NotificationFake(
      error: const ApiException(message: 'Offline'),
    );
    final failedCubit = _cubit(failedRepository, _managerScope);
    addTearDown(failedCubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: failedCubit,
          child: const NotificationsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Could not load notifications'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    final emptyCubit = _cubit(
      _NotificationFake(records: [], count: 0),
      _managerScope,
    );
    addTearDown(emptyCubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: emptyCubit,
          child: const NotificationsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No notifications'), findsOneWidget);
  });

  testWidgets(
    'known manager leave notification verifies destination before routing',
    (tester) async {
      final repository = _NotificationFake(
        records: [
          _notification(
            type: NotificationType.leaveRequestCreated,
            data: const {
              'leaveRequestId': _leaveId,
              'employeeMembershipId': '040e52de-05b9-46b8-80ca-e7df3ef7444b',
            },
          ),
        ],
      );
      final cubit = _cubit(repository, _managerScope);
      addTearDown(cubit.close);
      final router = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (_, _) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/attendance',
            builder: (_, _) =>
                const Scaffold(body: Text('Attendance destination')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        RepositoryProvider<LeaveRequestRepository>.value(
          value: _LeaveFake(),
          child: BlocProvider.value(
            value: cubit,
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('notification-$_notificationId')));
      await tester.pumpAndSettle();
      expect(find.text('Attendance destination'), findsOneWidget);
    },
  );

  testWidgets('wrong-role destination does not navigate', (tester) async {
    final repository = _NotificationFake(
      records: [
        _notification(
          type: NotificationType.leaveRequestCreated,
          data: const {'leaveRequestId': 'invalid'},
        ),
      ],
    );
    final cubit = _cubit(repository, _employeeScope);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const NotificationsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notification-$_notificationId')));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsScreen), findsOneWidget);
    ToastService.dismissAll();
  });

  testWidgets('cross-workspace notification is rejected and cannot navigate', (
    tester,
  ) async {
    final repository = _NotificationFake(
      records: [
        _notification(
          type: NotificationType.leaveRequestCreated,
          workspaceId: '8e7e0e38-e2c4-4306-a960-e949e7be38a8',
          data: const {'leaveRequestId': _leaveId},
        ),
      ],
    );
    final cubit = _cubit(repository, _managerScope);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const NotificationsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(
      find.byKey(const Key('notification-$_notificationId')),
      findsNothing,
    );
    expect(find.text('Could not load notifications'), findsOneWidget);
  });

  testWidgets('invalid payload ID does not navigate', (tester) async {
    final repository = _NotificationFake(
      records: [
        _notification(
          type: NotificationType.leaveRequestCreated,
          data: const {'leaveRequestId': 'invalid'},
        ),
      ],
    );
    final cubit = _cubit(repository, _managerScope);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const NotificationsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notification-$_notificationId')));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(
      find.text('This notification destination is no longer available.'),
      findsOneWidget,
    );
    ToastService.dismissAll();
  });

  testWidgets(
    'deleted destination shows a safe error and retains notification',
    (tester) async {
      final repository = _NotificationFake(
        records: [
          _notification(
            type: NotificationType.leaveRequestCreated,
            data: const {
              'leaveRequestId': _leaveId,
              'employeeMembershipId': '040e52de-05b9-46b8-80ca-e7df3ef7444b',
            },
          ),
        ],
      );
      final cubit = _cubit(repository, _managerScope);
      addTearDown(cubit.close);
      final router = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (_, _) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/attendance',
            builder: (_, _) => const Text('destination'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        RepositoryProvider<LeaveRequestRepository>.value(
          value: _DeletedLeaveFake(),
          child: BlocProvider.value(
            value: cubit,
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('notification-$_notificationId')));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsScreen), findsOneWidget);
      expect(
        find.text('This notification destination is no longer available.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('notification-$_notificationId')),
        findsOneWidget,
      );
      ToastService.dismissAll();
    },
  );
}

class _LeaveFake implements LeaveRequestRepository {
  @override
  Future<LeaveRequestRecord> getWorkspace(
    String workspaceId,
    String requestId,
  ) async => _leave();
  @override
  Future<LeaveRequestRecord> getMine(String requestId) async => _leave();
  @override
  Future<LeaveRequestRecord> cancelMine(String requestId) =>
      throw UnimplementedError();
  @override
  Future<LeaveRequestRecord> create(
    String workspaceId,
    CreateLeaveRequestInput input,
  ) => throw UnimplementedError();
  @override
  Future<LeaveRequestPage> listMine(
    String workspaceId,
    LeaveRequestQuery query,
  ) => throw UnimplementedError();
  @override
  Future<LeaveRequestPage> listWorkspace(
    String workspaceId,
    LeaveRequestQuery query,
  ) => throw UnimplementedError();
  @override
  Future<LeaveRequestRecord> review(
    String workspaceId,
    String requestId,
    LeaveReviewDecision decision, {
    String? rejectionReason,
  }) => throw UnimplementedError();
}

class _DeletedLeaveFake extends _LeaveFake {
  @override
  Future<LeaveRequestRecord> getWorkspace(
    String workspaceId,
    String requestId,
  ) => throw const ApiException(
    statusCode: 404,
    code: 'NOTIFICATION_NOT_FOUND',
    message: 'That notification is no longer available.',
  );
}

LeaveRequestRecord _leave() => LeaveRequestRecord(
  id: _leaveId,
  workspaceId: _workspaceId,
  employeeMembershipId: '040e52de-05b9-46b8-80ca-e7df3ef7444b',
  type: LeaveRequestType.annualLeave,
  status: LeaveRequestStatus.pending,
  startsAt: DateTime.utc(2030),
  endsAt: DateTime.utc(2030, 1, 2),
  reason: 'Family event',
  createdAt: DateTime.utc(2029),
  updatedAt: DateTime.utc(2029),
  employee: const ShiftEmployeeSummary(
    membershipId: '040e52de-05b9-46b8-80ca-e7df3ef7444b',
    profileId: 'profile',
    role: WorkspaceRole.employee,
    membershipStatus: MembershipStatus.active,
  ),
);
