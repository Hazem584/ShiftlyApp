import 'package:equatable/equatable.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';

sealed class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

final class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

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

final class DashboardError extends DashboardState {
  const DashboardError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}

void validateDashboardData(FeatureSessionScope scope, DashboardData data) {
  if (data.timezone != scope.timezone) {
    throw const FormatException('Dashboard timezone does not match session');
  }
  if (data is ManagerDashboardData && !scope.isManager) {
    throw const FormatException('Manager dashboard returned to employee');
  }
  if (data is EmployeeDashboardData &&
      (!scope.isEmployee || data.employee.membershipId != scope.membershipId)) {
    throw const FormatException('Employee dashboard identity mismatch');
  }
}

Failure dashboardFailure(Object error) => error is ApiException
    ? error.toFailure()
    : const Failure(message: 'We could not load your dashboard. Try again.');
