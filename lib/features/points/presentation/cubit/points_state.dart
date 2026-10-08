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
    this.wallet,
    this.calendar = const [],
    this.history = const [],
    this.achievements = const [],
    this.visibleMonth,
    this.historyPage = 1,
    this.historyTotalPages = 0,
    this.failure,
    this.partialFailure,
    this.domainCode,
  });

  final bool initialLoading;
  final bool refreshing;
  final bool loadingCalendar;
  final bool loadingMoreHistory;
  final bool redeeming;
  final bool redemptionSucceeded;
  final bool canRetryRedemption;
  final PointsWallet? wallet;
  final List<PerformanceDay> calendar;
  final List<PointLedgerEntry> history;
  final List<Achievement> achievements;
  final DateTime? visibleMonth;
  final int historyPage;
  final int historyTotalPages;
  final Failure? failure;
  final Failure? partialFailure;
  final String? domainCode;

  bool get hasMoreHistory => historyPage < historyTotalPages;

  PointsState copyWith({
    bool? refreshing,
    bool? loadingCalendar,
    bool? loadingMoreHistory,
    bool? redeeming,
    bool? redemptionSucceeded,
    bool? canRetryRedemption,
    PointsWallet? wallet,
    List<PerformanceDay>? calendar,
    List<PointLedgerEntry>? history,
    List<Achievement>? achievements,
    DateTime? visibleMonth,
    int? historyPage,
    int? historyTotalPages,
    Failure? failure,
    Failure? partialFailure,
    String? domainCode,
    bool clearFailure = false,
    bool clearPartialFailure = false,
    bool clearDomainCode = false,
  }) => PointsState(
    initialLoading: false,
    refreshing: refreshing ?? this.refreshing,
    loadingCalendar: loadingCalendar ?? this.loadingCalendar,
    loadingMoreHistory: loadingMoreHistory ?? this.loadingMoreHistory,
    redeeming: redeeming ?? this.redeeming,
    redemptionSucceeded: redemptionSucceeded ?? this.redemptionSucceeded,
    canRetryRedemption: canRetryRedemption ?? this.canRetryRedemption,
    wallet: wallet ?? this.wallet,
    calendar: calendar ?? this.calendar,
    history: history ?? this.history,
    achievements: achievements ?? this.achievements,
    visibleMonth: visibleMonth ?? this.visibleMonth,
    historyPage: historyPage ?? this.historyPage,
    historyTotalPages: historyTotalPages ?? this.historyTotalPages,
    failure: clearFailure ? null : failure ?? this.failure,
    partialFailure: clearPartialFailure
        ? null
        : partialFailure ?? this.partialFailure,
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
    wallet,
    calendar,
    history,
    achievements,
    visibleMonth,
    historyPage,
    historyTotalPages,
    failure,
    partialFailure,
    domainCode,
  ];
}
