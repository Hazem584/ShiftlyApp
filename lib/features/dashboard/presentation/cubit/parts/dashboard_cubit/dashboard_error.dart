part of '../../dashboard_cubit.dart';

final class DashboardError extends DashboardState {
  const DashboardError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
