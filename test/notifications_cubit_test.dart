import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/network/api_model_parser.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/notifications/data/notification_repository.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_cubit.dart';

const _managerA = FeatureSessionScope(
  userId: 'user-a',
  workspaceId: 'workspace-a',
  membershipId: 'manager-a',
  timezone: 'Etc/UTC',
  role: WorkspaceRole.manager,
);
const _managerB = FeatureSessionScope(
  userId: 'user-a',
  workspaceId: 'workspace-b',
  membershipId: 'manager-b',
  timezone: 'Etc/UTC',
  role: WorkspaceRole.manager,
);
const _employeeA = FeatureSessionScope(
  userId: 'user-a',
  workspaceId: 'workspace-a',
  membershipId: 'employee-a',
  timezone: 'Etc/UTC',
  role: WorkspaceRole.employee,
);

NotificationRecord _record({
  String id = 'notification-1',
  String workspaceId = 'workspace-a',
  DateTime? readAt,
}) => NotificationRecord(
  id: id,
  workspaceId: workspaceId,
  type: NotificationType.shiftAssigned,
  title: 'Shift assigned',
  message: 'A shift was assigned.',
  readAt: readAt,
  createdAt: DateTime.utc(2030),
  updatedAt: DateTime.utc(2030),
);

NotificationPage _page(
  List<NotificationRecord> records, {
  int page = 1,
  int totalPages = 1,
}) => NotificationPage(
  data: records,
  pagination: ApiPagination(
    page: page,
    limit: 20,
    total: records.length,
    totalPages: totalPages,
  ),
);

class _Fake implements NotificationRepository {
  final listCompleters = <Completer<NotificationPage>>[];
  NotificationPage page = _page([_record()]);
  Object? listError;
  Object? markError;
  Object? markAllError;
  Object? deleteError;
  int count = 1;
  int listCalls = 0;
  int markCalls = 0;
  int markAllCalls = 0;
  int deleteCalls = 0;

  @override
  Future<NotificationPage> list(
    String workspaceId,
    NotificationQuery query,
  ) async {
    listCalls += 1;
    if (listCompleters.isNotEmpty) return listCompleters.removeAt(0).future;
    if (listError != null) throw listError!;
    if (query.page > 1) {
      return _page(
        [_record(), _record(id: 'notification-2', workspaceId: workspaceId)],
        page: 2,
        totalPages: 2,
      );
    }
    return page;
  }

  @override
  Future<int> unreadCount() async => count;

  @override
  Future<NotificationRecord> markRead(String notificationId) async {
    markCalls += 1;
    if (markError != null) throw markError!;
    count = 0;
    return _record(id: notificationId, readAt: DateTime.utc(2030, 1, 2));
  }

  @override
  Future<int> markAllRead(String workspaceId) async {
    markAllCalls += 1;
    if (markAllError != null) throw markAllError!;
    count = 0;
    page = _page([_record(readAt: DateTime.utc(2030, 1, 2))]);
    return 1;
  }

  @override
  Future<bool> delete(String notificationId) async {
    deleteCalls += 1;
    if (deleteError != null) throw deleteError!;
    count = 0;
    return true;
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test(
    'loads records and global unread count for an authorized scope',
    () async {
      final repository = _Fake();
      final cubit = NotificationsCubit(repository)..bindSession(_managerA);
      expect(cubit.state.initialLoading, isTrue);
      await _settle();
      expect(cubit.state.initialLoading, isFalse);
      expect(cubit.state.notifications, hasLength(1));
      expect(cubit.state.unreadCount, 1);
      await cubit.close();
    },
  );

  test('supports an empty state and refresh failure retains records', () async {
    final repository = _Fake()..page = _page([]);
    final cubit = NotificationsCubit(repository)..bindSession(_managerA);
    await _settle();
    expect(cubit.state.notifications, isEmpty);
    repository.page = _page([_record()]);
    await cubit.load();
    repository.listError = const ApiException(message: 'Offline');
    await cubit.load(refresh: true);
    expect(cubit.state.notifications, hasLength(1));
    expect(cubit.state.failure?.message, 'Offline');
    await cubit.close();
  });

  test(
    'paginates with deduplication and suppresses duplicate list calls',
    () async {
      final completer = Completer<NotificationPage>();
      final repository = _Fake()
        ..page = _page([_record()], totalPages: 2)
        ..listCompleters.add(completer);
      final cubit = NotificationsCubit(repository)..bindSession(_managerA);
      cubit.load();
      expect(repository.listCalls, 1);
      completer.complete(repository.page);
      await _settle();
      await cubit.loadMore();
      expect(cubit.state.notifications.map((item) => item.id), [
        'notification-1',
        'notification-2',
      ]);
      await cubit.close();
    },
  );

  test(
    'mark-one uses canonical response and prevents duplicate mutation',
    () async {
      final completer = Completer<NotificationRecord>();
      final repository = _CompletingFake(markCompleter: completer);
      final cubit = NotificationsCubit(repository)..bindSession(_managerA);
      await _settle();
      final first = cubit.markRead('notification-1');
      expect(
        await cubit.markRead('notification-1'),
        NotificationMutationResult.busy,
      );
      completer.complete(_record(readAt: DateTime.utc(2030, 1, 2)));
      expect(await first, NotificationMutationResult.success);
      expect(cubit.state.notifications.single.isUnread, isFalse);
      await cubit.close();
    },
  );

  test('mark-one, mark-all, and delete failures retain records', () async {
    final repository = _Fake();
    final cubit = NotificationsCubit(repository)..bindSession(_managerA);
    await _settle();
    repository.markError = const ApiException(message: 'Mark failed');
    expect(
      await cubit.markRead('notification-1'),
      NotificationMutationResult.failure,
    );
    repository.markAllError = const ApiException(message: 'All failed');
    expect(await cubit.markAllRead(), NotificationMutationResult.failure);
    repository.deleteError = const ApiException(message: 'Delete failed');
    expect(
      await cubit.delete('notification-1'),
      NotificationMutationResult.failure,
    );
    expect(cubit.state.notifications, hasLength(1));
    await cubit.close();
  });

  test(
    'mark-all reloads canonical state and delete waits for acknowledgement',
    () async {
      final repository = _Fake();
      final cubit = NotificationsCubit(repository)..bindSession(_managerA);
      await _settle();
      expect(await cubit.markAllRead(), NotificationMutationResult.success);
      expect(cubit.state.notifications.single.isUnread, isFalse);
      expect(cubit.state.unreadCount, 0);
      expect(
        await cubit.delete('notification-1'),
        NotificationMutationResult.success,
      );
      expect(cubit.state.notifications, isEmpty);
      await cubit.close();
    },
  );

  test(
    'workspace switch and logout reject stale responses immediately',
    () async {
      final first = Completer<NotificationPage>();
      final second = Completer<NotificationPage>();
      final repository = _Fake()..listCompleters.addAll([first, second]);
      final cubit = NotificationsCubit(repository)..bindSession(_managerA);
      await _settle();
      cubit.bindSession(_managerB);
      expect(cubit.state.notifications, isEmpty);
      first.complete(_page([_record()]));
      second.complete(_page([_record(workspaceId: 'workspace-b')]));
      await _settle();
      expect(cubit.state.notifications.single.workspaceId, 'workspace-b');
      cubit.bindSession(null);
      expect(cubit.state.notifications, isEmpty);
      await cubit.close();
    },
  );

  test(
    'role/user changes reset while identical token refresh does not',
    () async {
      final repository = _Fake();
      final cubit = NotificationsCubit(repository)..bindSession(_managerA);
      await _settle();
      final calls = repository.listCalls;
      cubit.bindSession(_managerA);
      expect(repository.listCalls, calls);
      cubit.bindSession(_employeeA);
      await _settle();
      expect(repository.listCalls, calls + 1);
      cubit.bindSession(
        const FeatureSessionScope(
          userId: 'user-b',
          workspaceId: 'workspace-a',
          membershipId: 'employee-b',
          timezone: 'Etc/UTC',
          role: WorkspaceRole.employee,
        ),
      );
      await _settle();
      expect(repository.listCalls, calls + 2);
      await cubit.close();
    },
  );

  test(
    'cross-workspace responses are rejected without exposing rows',
    () async {
      final repository = _Fake()
        ..page = _page([_record(workspaceId: 'workspace-b')]);
      final cubit = NotificationsCubit(repository)..bindSession(_managerA);
      await _settle();
      expect(cubit.state.notifications, isEmpty);
      expect(cubit.state.failure, isNotNull);
      await cubit.close();
    },
  );

  test('mark-all and delete suppress duplicate mutations', () async {
    final markAllCompleter = Completer<int>();
    final deleteCompleter = Completer<bool>();
    final repository = _MutationCompletingFake(
      markAllCompleter: markAllCompleter,
      deleteCompleter: deleteCompleter,
    );
    final cubit = NotificationsCubit(repository)..bindSession(_managerA);
    await _settle();

    final markAll = cubit.markAllRead();
    expect(await cubit.markAllRead(), NotificationMutationResult.busy);
    markAllCompleter.complete(1);
    expect(await markAll, NotificationMutationResult.success);
    expect(repository.markAllCalls, 1);

    final delete = cubit.delete('notification-1');
    expect(
      await cubit.delete('notification-1'),
      NotificationMutationResult.busy,
    );
    deleteCompleter.complete(true);
    expect(await delete, NotificationMutationResult.success);
    expect(repository.deleteCalls, 1);
    await cubit.close();
  });

  test('unknown roles and absent sessions never request notifications', () {
    final repository = _Fake();
    final cubit = NotificationsCubit(repository)
      ..bindSession(
        const FeatureSessionScope(
          userId: 'user-a',
          workspaceId: 'workspace-a',
          membershipId: 'membership-a',
          timezone: 'Etc/UTC',
          role: WorkspaceRole.unknown,
        ),
      );
    expect(repository.listCalls, 0);
    expect(cubit.state.notifications, isEmpty);
    cubit.bindSession(null);
    expect(repository.listCalls, 0);
    return cubit.close();
  });
}

class _CompletingFake extends _Fake {
  _CompletingFake({required this.markCompleter});
  final Completer<NotificationRecord> markCompleter;

  @override
  Future<NotificationRecord> markRead(String notificationId) {
    markCalls += 1;
    return markCompleter.future;
  }
}

class _MutationCompletingFake extends _Fake {
  _MutationCompletingFake({
    required this.markAllCompleter,
    required this.deleteCompleter,
  });

  final Completer<int> markAllCompleter;
  final Completer<bool> deleteCompleter;

  @override
  Future<int> markAllRead(String workspaceId) {
    markAllCalls += 1;
    return markAllCompleter.future;
  }

  @override
  Future<bool> delete(String notificationId) {
    deleteCalls += 1;
    return deleteCompleter.future;
  }
}
