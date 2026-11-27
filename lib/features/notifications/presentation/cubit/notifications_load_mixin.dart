import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_cubit_base.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_state.dart';

mixin NotificationsLoadMixin on NotificationsCubitBase {
  Future<void> load({bool refresh = false}) async {
    final activeScope = currentScope;
    if (activeScope == null || listInFlight) return;
    listInFlight = true;
    final gen = generation, requestId = ++listRequestId, previous = state;
    emit(
      refresh && previous.notifications.isNotEmpty
          ? previous.copyWith(refreshing: true, clearFailure: true)
          : NotificationsState(
              query: previous.query,
              unreadCount: previous.unreadCount,
            ),
    );
    try {
      final q = previous.query.copyWith(page: 1);
      final results = await Future.wait<Object>([
        repository.list(activeScope.workspaceId, q),
        repository.unreadCount(),
      ]);
      if (!isCurrentList(activeScope, gen, requestId)) return;
      final page = results[0] as NotificationPage;
      validatePage(activeScope, page);
      emit(
        NotificationsState(
          initialLoading: false,
          notifications: page.data,
          query: q,
          page: page.pagination.page,
          totalPages: page.pagination.totalPages,
          unreadCount: results[1] as int,
        ),
      );
    } catch (error) {
      if (!isCurrentList(activeScope, gen, requestId)) return;
      final failure = toFailure(error, 'Unable to load notifications.');
      emit(
        refresh && previous.notifications.isNotEmpty
            ? previous.copyWith(refreshing: false, failure: failure)
            : NotificationsState(
                initialLoading: false,
                query: previous.query,
                unreadCount: previous.unreadCount,
                failure: failure,
              ),
      );
    } finally {
      if (isScopeCurrent(activeScope, gen)) listInFlight = false;
    }
  }
}
