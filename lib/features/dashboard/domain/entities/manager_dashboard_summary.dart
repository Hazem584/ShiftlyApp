import 'package:equatable/equatable.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';

class ManagerDashboardSummary extends Equatable {
  const ManagerDashboardSummary({
    required this.totalEmployees,
    required this.scheduledToday,
    required this.clockedInNow,
    required this.completedToday,
    required this.lateToday,
    required this.missedToday,
    required this.onApprovedLeave,
    required this.pendingLeaveRequests,
    required this.unreadNotifications,
  });

  final int totalEmployees;
  final int scheduledToday;
  final int clockedInNow;
  final int completedToday;
  final int lateToday;
  final int missedToday;
  final int onApprovedLeave;
  final int pendingLeaveRequests;
  final int unreadNotifications;

  factory ManagerDashboardSummary.fromJson(
    Map<String, Object?> json,
  ) => ManagerDashboardSummary(
    totalEmployees: ApiModelParser.integer(json, 'totalEmployees'),
    scheduledToday: ApiModelParser.integer(json, 'scheduledToday'),
    clockedInNow: ApiModelParser.integer(json, 'clockedInNow'),
    completedToday: ApiModelParser.integer(json, 'completedToday'),
    lateToday: ApiModelParser.integer(json, 'lateToday'),
    missedToday: ApiModelParser.integer(json, 'missedToday'),
    onApprovedLeave: ApiModelParser.integer(json, 'onApprovedLeave'),
    pendingLeaveRequests: ApiModelParser.integer(json, 'pendingLeaveRequests'),
    unreadNotifications: ApiModelParser.integer(json, 'unreadNotifications'),
  );

  @override
  List<Object?> get props => [
    totalEmployees,
    scheduledToday,
    clockedInNow,
    completedToday,
    lateToday,
    missedToday,
    onApprovedLeave,
    pendingLeaveRequests,
    unreadNotifications,
  ];
}
