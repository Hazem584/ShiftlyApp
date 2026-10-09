import 'package:equatable/equatable.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/dashboard/domain/entities/dashboard_attendance.dart';
import 'package:shiftly/features/dashboard/domain/entities/dashboard_leave_preview.dart';
import 'package:shiftly/features/dashboard/domain/entities/dashboard_models_parsers.dart';
import 'package:shiftly/features/dashboard/domain/entities/dashboard_shift_preview.dart';
import 'package:shiftly/features/dashboard/domain/entities/employee_dashboard_identity.dart';
import 'package:shiftly/features/dashboard/domain/entities/employee_dashboard_leave.dart';
import 'package:shiftly/features/dashboard/domain/entities/employee_dashboard_shift.dart';
import 'package:shiftly/features/dashboard/domain/entities/employee_dashboard_summary.dart';
import 'package:shiftly/features/dashboard/domain/entities/manager_dashboard_summary.dart';

sealed class DashboardData extends Equatable {
  const DashboardData({
    required this.date,
    required this.timezone,
    required this.generatedAt,
  });

  final String date;
  final String timezone;
  final DateTime generatedAt;
  bool get isEmpty;
}

class EmployeeDashboardData extends DashboardData {
  const EmployeeDashboardData({
    required super.date,
    required super.timezone,
    required super.generatedAt,
    required this.employee,
    required this.summary,
    required this.recentLeaveRequests,
    this.todayShift,
    this.attendance,
    this.nextShift,
  });

  final EmployeeDashboardIdentity employee;
  final EmployeeDashboardShift? todayShift;
  final DashboardAttendance? attendance;
  final EmployeeDashboardShift? nextShift;
  final EmployeeDashboardSummary summary;
  final List<EmployeeDashboardLeave> recentLeaveRequests;

  factory EmployeeDashboardData.fromJson(Map<String, Object?> json) {
    final todayShift = ApiModelParser.optionalMap(
      json['todayShift'],
      'todayShift',
    );
    final attendance = ApiModelParser.optionalMap(
      json['attendance'],
      'attendance',
    );
    final nextShift = ApiModelParser.optionalMap(
      json['nextShift'],
      'nextShift',
    );
    return EmployeeDashboardData(
      date: dashboardModelsDateOnly(json, 'date'),
      timezone: ApiModelParser.string(json, 'timezone'),
      generatedAt: ApiModelParser.date(json, 'generatedAt'),
      employee: EmployeeDashboardIdentity.fromJson(
        ApiModelParser.map(json['employee'], 'employee'),
      ),
      todayShift: todayShift == null
          ? null
          : EmployeeDashboardShift.fromJson(todayShift),
      attendance: attendance == null
          ? null
          : DashboardAttendance.fromJson(attendance),
      nextShift: nextShift == null
          ? null
          : EmployeeDashboardShift.fromJson(nextShift),
      summary: EmployeeDashboardSummary.fromJson(
        ApiModelParser.map(json['summary'], 'summary'),
      ),
      recentLeaveRequests:
          ApiModelParser.list(
                json['recentLeaveRequests'],
                'recentLeaveRequests',
              )
              .map(
                (item) => EmployeeDashboardLeave.fromJson(
                  ApiModelParser.map(item, 'recentLeaveRequest'),
                ),
              )
              .toList(growable: false),
    );
  }

  @override
  bool get isEmpty =>
      todayShift == null &&
      nextShift == null &&
      recentLeaveRequests.isEmpty &&
      summary.pendingLeaveRequests == 0 &&
      summary.approvedLeaveRequests == 0;

  @override
  List<Object?> get props => [
    date,
    timezone,
    generatedAt,
    employee,
    todayShift,
    attendance,
    nextShift,
    summary,
    recentLeaveRequests,
  ];
}

class ManagerDashboardData extends DashboardData {
  const ManagerDashboardData({
    required super.date,
    required super.timezone,
    required super.generatedAt,
    required this.summary,
    required this.todayShifts,
    required this.pendingLeaveRequests,
  });

  final ManagerDashboardSummary summary;
  final List<DashboardShiftPreview> todayShifts;
  final List<DashboardLeavePreview> pendingLeaveRequests;

  factory ManagerDashboardData.fromJson(Map<String, Object?> json) =>
      ManagerDashboardData(
        date: dashboardModelsDateOnly(json, 'date'),
        timezone: ApiModelParser.string(json, 'timezone'),
        generatedAt: ApiModelParser.date(json, 'generatedAt'),
        summary: ManagerDashboardSummary.fromJson(
          ApiModelParser.map(json['summary'], 'summary'),
        ),
        todayShifts: ApiModelParser.list(json['todayShifts'], 'todayShifts')
            .map(
              (item) => DashboardShiftPreview.fromJson(
                ApiModelParser.map(item, 'todayShift'),
              ),
            )
            .toList(growable: false),
        pendingLeaveRequests:
            ApiModelParser.list(
                  json['pendingLeaveRequests'],
                  'pendingLeaveRequests',
                )
                .map(
                  (item) => DashboardLeavePreview.fromJson(
                    ApiModelParser.map(item, 'pendingLeaveRequest'),
                  ),
                )
                .toList(growable: false),
      );

  @override
  bool get isEmpty =>
      summary.totalEmployees == 0 &&
      todayShifts.isEmpty &&
      pendingLeaveRequests.isEmpty;

  @override
  List<Object?> get props => [
    date,
    timezone,
    generatedAt,
    summary,
    todayShifts,
    pendingLeaveRequests,
  ];
}
