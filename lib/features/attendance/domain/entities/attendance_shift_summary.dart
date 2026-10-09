import 'package:equatable/equatable.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

class AttendanceShiftSummary extends Equatable {
  const AttendanceShiftSummary({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    required this.breakMinutes,
    required this.graceMinutes,
    required this.status,
    this.notes,
  });
  final String id;
  final DateTime startsAt;
  final DateTime endsAt;
  final int breakMinutes;
  final int graceMinutes;
  final String? notes;
  final ShiftStatus status;

  factory AttendanceShiftSummary.fromJson(Map<String, Object?> json) =>
      AttendanceShiftSummary(
        id: ApiModelParser.string(json, 'id'),
        startsAt: ApiModelParser.date(json, 'startsAt'),
        endsAt: ApiModelParser.date(json, 'endsAt'),
        breakMinutes: ApiModelParser.integer(json, 'breakMinutes'),
        graceMinutes: ApiModelParser.integer(json, 'graceMinutes'),
        notes: ApiModelParser.optionalString(json['notes']),
        status: ShiftStatus.parse(json['status']),
      );

  @override
  List<Object?> get props => [
    id,
    startsAt,
    endsAt,
    breakMinutes,
    graceMinutes,
    notes,
    status,
  ];
}
