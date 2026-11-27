import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/dashboard/domain/entities/dashboard_attendance.dart';
import 'package:shiftly/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:shiftly/features/dashboard/domain/entities/dashboard_leave_preview.dart';
import 'package:shiftly/features/dashboard/domain/entities/dashboard_models_parsers.dart';
import 'package:shiftly/features/dashboard/domain/entities/dashboard_shift_preview.dart';
import 'package:shiftly/features/dashboard/domain/entities/employee_dashboard_identity.dart';
import 'package:shiftly/features/dashboard/domain/entities/employee_dashboard_leave.dart';
import 'package:shiftly/features/dashboard/domain/entities/employee_dashboard_shift.dart';
import 'package:shiftly/features/dashboard/domain/entities/employee_dashboard_summary.dart';
import 'package:shiftly/features/dashboard/domain/entities/manager_dashboard_summary.dart';

EmployeeDashboardData parseEmployeeDashboardData(Map<String, Object?> json) {
  final todayShift = ApiModelParser.optionalMap(
    json['todayShift'],
    'todayShift',
  );
  final attendance = ApiModelParser.optionalMap(
    json['attendance'],
    'attendance',
  );
  final nextShift = ApiModelParser.optionalMap(json['nextShift'], 'nextShift');
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
        ApiModelParser.list(json['recentLeaveRequests'], 'recentLeaveRequests')
            .map(
              (item) => EmployeeDashboardLeave.fromJson(
                ApiModelParser.map(item, 'recentLeaveRequest'),
              ),
            )
            .toList(growable: false),
  );
}

ManagerDashboardData parseManagerDashboardData(Map<String, Object?> json) =>
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
