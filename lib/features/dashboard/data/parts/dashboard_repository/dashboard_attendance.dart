part of '../../dashboard_repository.dart';

class DashboardAttendance extends Equatable {
  const DashboardAttendance({
    required this.id,
    required this.status,
    required this.reviewStatus,
    required this.clockedInAt,
    required this.isLate,
    this.clockedOutAt,
    this.workedMinutes,
  });

  final String id;
  final DashboardAttendanceStatus status;
  final AttendanceReviewStatus reviewStatus;
  final DateTime clockedInAt;
  final DateTime? clockedOutAt;
  final bool isLate;
  final int? workedMinutes;

  factory DashboardAttendance.fromJson(Map<String, Object?> json) =>
      DashboardAttendance(
        id: _uuid(json, 'id'),
        status: DashboardAttendanceStatus.parse(json['status']),
        reviewStatus: AttendanceReviewStatus.parse(json['reviewStatus']),
        clockedInAt: ApiModelParser.date(json, 'clockedInAt'),
        clockedOutAt: ApiModelParser.optionalDate(json['clockedOutAt']),
        isLate: _boolean(json, 'isLate'),
        workedMinutes: ApiModelParser.optionalInteger(json['workedMinutes']),
      );

  @override
  List<Object?> get props => [
    id,
    status,
    reviewStatus,
    clockedInAt,
    clockedOutAt,
    isLate,
    workedMinutes,
  ];
}
