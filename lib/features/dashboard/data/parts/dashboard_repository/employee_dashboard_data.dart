part of '../../dashboard_repository.dart';

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
      date: _dateOnly(json, 'date'),
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
