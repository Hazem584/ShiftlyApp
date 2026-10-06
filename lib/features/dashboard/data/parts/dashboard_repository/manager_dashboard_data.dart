part of '../../dashboard_repository.dart';

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
        date: _dateOnly(json, 'date'),
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
