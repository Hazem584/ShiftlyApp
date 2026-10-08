part of 'points_cubit.dart';

class PointsState extends Equatable {
  const PointsState({
    this.initialLoading = true,
    this.refreshing = false,
    this.loadingCalendar = false,
    this.loadingMoreHistory = false,
    this.redeeming = false,
    this.redemptionSucceeded = false,
    this.canRetryRedemption = false,
    this.hasUnresolvedRedemption = false,
    this.unresolvedRedPoints = 0,
    this.wallet,
    this.calendar = const [],
    this.calendarMonth,
    this.history = const [],
    this.achievements = const [],
    this.visibleMonth,
    this.historyPage = 1,
    this.historyTotalPages = 0,
    this.failure,
    this.partialFailure,
    this.calendarFailure,
    this.domainCode,
  });

  final bool initialLoading;
  final bool refreshing;
  final bool loadingCalendar;
  final bool loadingMoreHistory;
  final bool redeeming;
  final bool redemptionSucceeded;
  final bool canRetryRedemption;
  final bool hasUnresolvedRedemption;
  final int unresolvedRedPoints;
  final PointsWallet? wallet;
  final List<PerformanceDay> calendar;
  final DateTime? calendarMonth;
  final List<PointLedgerEntry> history;
  final List<Achievement> achievements;
  final DateTime? visibleMonth;
  final int historyPage;
  final int historyTotalPages;
  final Failure? failure;
  final Failure? partialFailure;
  final Failure? calendarFailure;
  final String? domainCode;

  bool get hasMoreHistory => historyPage < historyTotalPages;
  bool get calendarMatchesVisibleMonth =>
      calendarMonth != null &&
      visibleMonth != null &&
      calendarMonth!.year == visibleMonth!.year &&
      calendarMonth!.month == visibleMonth!.month;
  List<PerformanceDay> get visibleCalendar =>
      calendarMatchesVisibleMonth ? calendar : const [];

  PointsState copyWith({
    bool? initialLoading,
    bool? refreshing,
    bool? loadingCalendar,
    bool? loadingMoreHistory,
    bool? redeeming,
    bool? redemptionSucceeded,
    bool? canRetryRedemption,
    bool? hasUnresolvedRedemption,
    int? unresolvedRedPoints,
    PointsWallet? wallet,
    List<PerformanceDay>? calendar,
    DateTime? calendarMonth,
    List<PointLedgerEntry>? history,
    List<Achievement>? achievements,
    DateTime? visibleMonth,
    int? historyPage,
    int? historyTotalPages,
    Failure? failure,
    Failure? partialFailure,
    Failure? calendarFailure,
    String? domainCode,
    bool clearFailure = false,
    bool clearPartialFailure = false,
    bool clearCalendarFailure = false,
    bool clearDomainCode = false,
  }) => PointsState(
    initialLoading: initialLoading ?? this.initialLoading,
    refreshing: refreshing ?? this.refreshing,
    loadingCalendar: loadingCalendar ?? this.loadingCalendar,
    loadingMoreHistory: loadingMoreHistory ?? this.loadingMoreHistory,
    redeeming: redeeming ?? this.redeeming,
    redemptionSucceeded: redemptionSucceeded ?? this.redemptionSucceeded,
    canRetryRedemption: canRetryRedemption ?? this.canRetryRedemption,
    hasUnresolvedRedemption:
        hasUnresolvedRedemption ?? this.hasUnresolvedRedemption,
    unresolvedRedPoints: unresolvedRedPoints ?? this.unresolvedRedPoints,
    wallet: wallet ?? this.wallet,
    calendar: calendar ?? this.calendar,
    calendarMonth: calendarMonth ?? this.calendarMonth,
    history: history ?? this.history,
    achievements: achievements ?? this.achievements,
    visibleMonth: visibleMonth ?? this.visibleMonth,
    historyPage: historyPage ?? this.historyPage,
    historyTotalPages: historyTotalPages ?? this.historyTotalPages,
    failure: clearFailure ? null : failure ?? this.failure,
    partialFailure:
        clearPartialFailure ? null : partialFailure ?? this.partialFailure,
    calendarFailure:
        clearCalendarFailure ? null : calendarFailure ?? this.calendarFailure,
    domainCode: clearDomainCode ? null : domainCode ?? this.domainCode,
  );

  @override
  List<Object?> get props => [
    initialLoading,
    refreshing,
    loadingCalendar,
    loadingMoreHistory,
    redeeming,
    redemptionSucceeded,
    canRetryRedemption,
    hasUnresolvedRedemption,
    unresolvedRedPoints,
    wallet,
    calendar,
    calendarMonth,
    history,
    achievements,
    visibleMonth,
    historyPage,
    historyTotalPages,
    failure,
    partialFailure,
    calendarFailure,
    domainCode,
  ];
}
