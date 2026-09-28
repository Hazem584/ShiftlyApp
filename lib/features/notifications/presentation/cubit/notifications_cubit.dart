import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/notifications/data/notification_repository.dart';

enum NotificationMutationResult { success, failure, busy, stale }

class NotificationsState extends Equatable {
  const NotificationsState({
    this.initialLoading = true,
    this.notifications = const [],
    this.query = const NotificationQuery(),
    this.page = 1,
    this.totalPages = 0,
    this.unreadCount = 0,
    this.refreshing = false,
    this.loadingMore = false,
    this.markingIds = const {},
    this.deletingIds = const {},
    this.markingAll = false,
    this.failure,
  });

  final bool initialLoading;
  final List<NotificationRecord> notifications;
  final NotificationQuery query;
  final int page;
  final int totalPages;
  final int unreadCount;
  final bool refreshing;
  final bool loadingMore;
  final Set<String> markingIds;
  final Set<String> deletingIds;
  final bool markingAll;
  final Failure? failure;

  bool get hasMore => page < totalPages;

  NotificationsState copyWith({
    bool? initialLoading,
    List<NotificationRecord>? notifications,
    NotificationQuery? query,
    int? page,
    int? totalPages,
    int? unreadCount,
    bool? refreshing,
    bool? loadingMore,
    Set<String>? markingIds,
    Set<String>? deletingIds,
    bool? markingAll,
    Failure? failure,
    bool clearFailure = false,
  }) => NotificationsState(
    initialLoading: initialLoading ?? this.initialLoading,
    notifications: notifications ?? this.notifications,
    query: query ?? this.query,
    page: page ?? this.page,
    totalPages: totalPages ?? this.totalPages,
    unreadCount: unreadCount ?? this.unreadCount,
    refreshing: refreshing ?? this.refreshing,
    loadingMore: loadingMore ?? this.loadingMore,
    markingIds: markingIds ?? this.markingIds,
    deletingIds: deletingIds ?? this.deletingIds,
    markingAll: markingAll ?? this.markingAll,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    initialLoading,
    notifications,
    query,
    page,
    totalPages,
    unreadCount,
    refreshing,
    loadingMore,
    markingIds,
    deletingIds,
    markingAll,
    failure,
  ];
}

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository) : super(const NotificationsState());

  final NotificationRepository _repository;
  FeatureSessionScope? _scope;
  var _generation = 0;
  var _listRequestId = 0;
  var _countRequestId = 0;
  var _listInFlight = false;

  FeatureSessionScope? get scope => _scope;

  void bindSession(FeatureSessionScope? scope) {
    final authorized = scope?.isManager == true || scope?.isEmployee == true
        ? scope
        : null;
    if (_scope == authorized) return;
    _scope = authorized;
    _generation += 1;
    _listRequestId += 1;
    _countRequestId += 1;
    _listInFlight = false;
    emit(const NotificationsState());
    if (authorized != null) unawaited(load());
  }

  Future<void> load({bool refresh = false}) async {
    final scope = _scope;
    if (scope == null || _listInFlight) return;
    _listInFlight = true;
    final generation = _generation;
    final requestId = ++_listRequestId;
    final previous = state;
    emit(
      refresh && previous.notifications.isNotEmpty
          ? previous.copyWith(refreshing: true, clearFailure: true)
          : NotificationsState(
              query: previous.query,
              unreadCount: previous.unreadCount,
            ),
    );
    try {
      final results = await Future.wait<Object>([
        _repository.list(scope.workspaceId, previous.query.copyWith(page: 1)),
        _repository.unreadCount(),
      ]);
      if (!_currentList(scope, generation, requestId)) return;
      final page = results[0] as NotificationPage;
      final unreadCount = results[1] as int;
      _validatePage(scope, page);
      emit(
        NotificationsState(
          initialLoading: false,
          notifications: page.data,
          query: previous.query.copyWith(page: 1),
          page: page.pagination.page,
          totalPages: page.pagination.totalPages,
          unreadCount: unreadCount,
        ),
      );
    } catch (error) {
      if (!_currentList(scope, generation, requestId)) return;
      final failure = _failure(error, 'Unable to load notifications.');
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
      if (_scopeCurrent(scope, generation)) _listInFlight = false;
    }
  }

  Future<void> loadMore() async {
    final scope = _scope;
    final previous = state;
    if (scope == null ||
        _listInFlight ||
        previous.loadingMore ||
        !previous.hasMore) {
      return;
    }
    _listInFlight = true;
    final generation = _generation;
    final requestId = ++_listRequestId;
    emit(previous.copyWith(loadingMore: true, clearFailure: true));
    try {
      final page = await _repository.list(
        scope.workspaceId,
        previous.query.copyWith(page: previous.page + 1),
      );
      if (!_currentList(scope, generation, requestId)) return;
      _validatePage(scope, page);
      final ids = previous.notifications.map((item) => item.id).toSet();
      emit(
        previous.copyWith(
          notifications: [
            ...previous.notifications,
            ...page.data.where((item) => ids.add(item.id)),
          ],
          page: page.pagination.page,
          totalPages: page.pagination.totalPages,
          loadingMore: false,
        ),
      );
    } catch (error) {
      if (!_currentList(scope, generation, requestId)) return;
      emit(
        previous.copyWith(
          loadingMore: false,
          failure: _failure(error, 'Unable to load more notifications.'),
        ),
      );
    } finally {
      if (_scopeCurrent(scope, generation)) _listInFlight = false;
    }
  }

  Future<void> refreshUnreadCount() async {
    final scope = _scope;
    if (scope == null) return;
    final generation = _generation;
    final requestId = ++_countRequestId;
    try {
      final count = await _repository.unreadCount();
      if (!_currentCount(scope, generation, requestId)) return;
      emit(state.copyWith(unreadCount: count));
    } catch (error) {
      if (!_currentCount(scope, generation, requestId)) return;
      emit(
        state.copyWith(
          failure: _failure(error, 'Unable to refresh unread notifications.'),
        ),
      );
    }
  }

  Future<NotificationMutationResult> markRead(String notificationId) async {
    final scope = _scope;
    if (scope == null) return NotificationMutationResult.failure;
    if (state.markingIds.contains(notificationId)) {
      return NotificationMutationResult.busy;
    }
    final current = state.notifications
        .where((item) => item.id == notificationId)
        .firstOrNull;
    if (current != null && !current.isUnread) {
      return NotificationMutationResult.success;
    }
    final generation = _generation;
    emit(
      state.copyWith(
        markingIds: {...state.markingIds, notificationId},
        clearFailure: true,
      ),
    );
    try {
      final record = await _repository.markRead(notificationId);
      if (!_scopeCurrent(scope, generation)) {
        return NotificationMutationResult.stale;
      }
      if (record.id != notificationId ||
          record.readAt == null ||
          record.workspaceId != scope.workspaceId) {
        _finishMark(
          notificationId,
          failure: const Failure(
            message: 'The server returned an invalid notification.',
            kind: FailureKind.server,
          ),
        );
        return NotificationMutationResult.failure;
      }
      _finishMark(notificationId, record: record);
      unawaited(refreshUnreadCount());
      return NotificationMutationResult.success;
    } catch (error) {
      if (!_scopeCurrent(scope, generation)) {
        return NotificationMutationResult.stale;
      }
      _finishMark(
        notificationId,
        failure: _failure(error, 'Unable to mark the notification as read.'),
      );
      return NotificationMutationResult.failure;
    }
  }

  Future<NotificationMutationResult> markAllRead() async {
    final scope = _scope;
    if (scope == null) return NotificationMutationResult.failure;
    if (state.markingAll) return NotificationMutationResult.busy;
    final generation = _generation;
    emit(state.copyWith(markingAll: true, clearFailure: true));
    try {
      await _repository.markAllRead(scope.workspaceId);
      if (!_scopeCurrent(scope, generation)) {
        return NotificationMutationResult.stale;
      }
      emit(state.copyWith(markingAll: false));
      await load(refresh: true);
      return _scopeCurrent(scope, generation)
          ? NotificationMutationResult.success
          : NotificationMutationResult.stale;
    } catch (error) {
      if (!_scopeCurrent(scope, generation)) {
        return NotificationMutationResult.stale;
      }
      emit(
        state.copyWith(
          markingAll: false,
          failure: _failure(error, 'Unable to mark all notifications as read.'),
        ),
      );
      return NotificationMutationResult.failure;
    }
  }

  Future<NotificationMutationResult> delete(String notificationId) async {
    final scope = _scope;
    if (scope == null) return NotificationMutationResult.failure;
    if (state.deletingIds.contains(notificationId)) {
      return NotificationMutationResult.busy;
    }
    final generation = _generation;
    emit(
      state.copyWith(
        deletingIds: {...state.deletingIds, notificationId},
        clearFailure: true,
      ),
    );
    try {
      final deleted = await _repository.delete(notificationId);
      if (!_scopeCurrent(scope, generation)) {
        return NotificationMutationResult.stale;
      }
      if (!deleted) {
        _finishDelete(
          notificationId,
          failure: const Failure(
            message: 'The server did not confirm deletion.',
            kind: FailureKind.server,
          ),
        );
        return NotificationMutationResult.failure;
      }
      _finishDelete(notificationId, remove: true);
      unawaited(refreshUnreadCount());
      return NotificationMutationResult.success;
    } catch (error) {
      if (!_scopeCurrent(scope, generation)) {
        return NotificationMutationResult.stale;
      }
      _finishDelete(
        notificationId,
        failure: _failure(error, 'Unable to delete the notification.'),
      );
      return NotificationMutationResult.failure;
    }
  }

  void _finishMark(
    String notificationId, {
    NotificationRecord? record,
    Failure? failure,
  }) {
    final marking = {...state.markingIds}..remove(notificationId);
    emit(
      state.copyWith(
        markingIds: marking,
        notifications: record == null
            ? state.notifications
            : state.notifications
                  .map((item) => item.id == notificationId ? record : item)
                  .toList(growable: false),
        failure: failure,
      ),
    );
  }

  void _finishDelete(
    String notificationId, {
    bool remove = false,
    Failure? failure,
  }) {
    final deleting = {...state.deletingIds}..remove(notificationId);
    emit(
      state.copyWith(
        deletingIds: deleting,
        notifications: remove
            ? state.notifications
                  .where((item) => item.id != notificationId)
                  .toList(growable: false)
            : state.notifications,
        failure: failure,
      ),
    );
  }

  void _validatePage(FeatureSessionScope scope, NotificationPage page) {
    if (page.data.any((item) => item.workspaceId != scope.workspaceId)) {
      throw const FormatException('Cross-workspace notification response');
    }
  }

  Failure _failure(Object error, String fallback) =>
      error is ApiException ? error.toFailure() : Failure(message: fallback);
  bool _currentList(FeatureSessionScope scope, int generation, int requestId) =>
      _scopeCurrent(scope, generation) && _listRequestId == requestId;
  bool _currentCount(
    FeatureSessionScope scope,
    int generation,
    int requestId,
  ) => _scopeCurrent(scope, generation) && _countRequestId == requestId;
  bool _scopeCurrent(FeatureSessionScope scope, int generation) =>
      !isClosed && _scope == scope && _generation == generation;
}
