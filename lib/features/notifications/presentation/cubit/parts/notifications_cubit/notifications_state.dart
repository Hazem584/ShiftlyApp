part of '../../notifications_cubit.dart';

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
