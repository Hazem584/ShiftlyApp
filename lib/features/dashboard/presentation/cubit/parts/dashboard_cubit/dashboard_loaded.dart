part of '../../dashboard_cubit.dart';

final class DashboardLoaded extends DashboardState {
  const DashboardLoaded({
    required this.data,
    this.refreshing = false,
    this.failure,
  });

  final DashboardData data;
  final bool refreshing;
  final Failure? failure;

  DashboardLoaded copyWith({
    DashboardData? data,
    bool? refreshing,
    Failure? failure,
    bool clearFailure = false,
  }) => DashboardLoaded(
    data: data ?? this.data,
    refreshing: refreshing ?? this.refreshing,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [data, refreshing, failure];
}
