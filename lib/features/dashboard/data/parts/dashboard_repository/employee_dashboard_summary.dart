part of '../../dashboard_repository.dart';

class EmployeeDashboardSummary extends Equatable {
  const EmployeeDashboardSummary({
    required this.pendingLeaveRequests,
    required this.approvedLeaveRequests,
    required this.unreadNotifications,
  });

  final int pendingLeaveRequests;
  final int approvedLeaveRequests;
  final int unreadNotifications;

  factory EmployeeDashboardSummary.fromJson(
    Map<String, Object?> json,
  ) => EmployeeDashboardSummary(
    pendingLeaveRequests: ApiModelParser.integer(json, 'pendingLeaveRequests'),
    approvedLeaveRequests: ApiModelParser.integer(
      json,
      'approvedLeaveRequests',
    ),
    unreadNotifications: ApiModelParser.integer(json, 'unreadNotifications'),
  );

  @override
  List<Object?> get props => [
    pendingLeaveRequests,
    approvedLeaveRequests,
    unreadNotifications,
  ];
}
