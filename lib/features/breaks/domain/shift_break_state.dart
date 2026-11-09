import 'package:equatable/equatable.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';

class ShiftBreakState extends Equatable {
  const ShiftBreakState({
    required this.allowedMinutes,
    this.plannedMinutes,
    this.lateDeductionMinutes = 0,
    this.reminderAt,
    this.startedAt,
    this.endedAt,
  });
  final int allowedMinutes;
  final int? plannedMinutes;
  final int lateDeductionMinutes;
  final DateTime? reminderAt, startedAt, endedAt;
  factory ShiftBreakState.fromJson(Map<String, Object?> json) =>
      ShiftBreakState(
        allowedMinutes: ApiModelParser.integer(json, 'allowedMinutes'),
        plannedMinutes: ApiModelParser.optionalInteger(json['plannedMinutes']),
        lateDeductionMinutes:
            ApiModelParser.optionalInteger(json['lateDeductionMinutes']) ?? 0,
        reminderAt: ApiModelParser.optionalDate(json['reminderAt']),
        startedAt: ApiModelParser.optionalDate(json['startedAt']),
        endedAt: ApiModelParser.optionalDate(json['endedAt']),
      );
  DateTime? get endsAt => startedAt == null
      ? null
      : endedAt ?? startedAt!.add(Duration(minutes: allowedMinutes));
  @override
  List<Object?> get props => [
    allowedMinutes,
    plannedMinutes,
    lateDeductionMinutes,
    reminderAt,
    startedAt,
    endedAt,
  ];
}
