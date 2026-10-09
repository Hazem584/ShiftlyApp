import 'package:equatable/equatable.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/dashboard/domain/entities/dashboard_attendance_status.dart';
import 'package:shiftly/features/dashboard/domain/entities/dashboard_models_parsers.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

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
        id: dashboardModelsUuid(json, 'id'),
        status: DashboardAttendanceStatus.parse(json['status']),
        reviewStatus: AttendanceReviewStatus.parse(json['reviewStatus']),
        clockedInAt: ApiModelParser.date(json, 'clockedInAt'),
        clockedOutAt: ApiModelParser.optionalDate(json['clockedOutAt']),
        isLate: dashboardModelsBoolean(json, 'isLate'),
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
