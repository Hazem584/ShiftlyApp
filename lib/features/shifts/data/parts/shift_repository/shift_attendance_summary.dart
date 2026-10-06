part of '../../shift_repository.dart';

class ShiftAttendanceSummary extends Equatable {
  const ShiftAttendanceSummary({
    required this.id,
    required this.clockInAt,
    required this.reviewStatus,
    required this.minutesLate,
    this.clockOutAt,
    this.workedMinutes,
  });

  final String id;
  final DateTime clockInAt;
  final DateTime? clockOutAt;
  final AttendanceReviewStatus reviewStatus;
  final int minutesLate;
  final int? workedMinutes;

  factory ShiftAttendanceSummary.fromJson(Map<String, Object?> json) =>
      ShiftAttendanceSummary(
        id: ApiModelParser.string(json, 'id'),
        clockInAt: ApiModelParser.date(json, 'clockInAt'),
        clockOutAt: ApiModelParser.optionalDate(json['clockOutAt']),
        reviewStatus: AttendanceReviewStatus.parse(json['reviewStatus']),
        minutesLate: ApiModelParser.integer(json, 'minutesLate'),
        workedMinutes: ApiModelParser.optionalInteger(json['workedMinutes']),
      );

  @override
  List<Object?> get props => [
    id,
    clockInAt,
    clockOutAt,
    reviewStatus,
    minutesLate,
    workedMinutes,
  ];
}
