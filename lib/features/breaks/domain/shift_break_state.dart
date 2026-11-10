import 'package:equatable/equatable.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';

class ShiftBreakState extends Equatable {
  const ShiftBreakState({
    required this.allowedMinutes,
    this.plannedMinutes,
    this.consumedSeconds,
    this.revision,
    this.shiftEndsAt,
    this.lateDeductionMinutes = 0,
    this.reminderAt,
    this.startedAt,
    this.endedAt,
  });
  final int allowedMinutes;
  final int? plannedMinutes, consumedSeconds, revision;
  final DateTime? shiftEndsAt;
  final int lateDeductionMinutes;
  final DateTime? reminderAt, startedAt, endedAt;
  factory ShiftBreakState.fromJson(Map<String, Object?> json) =>
      ShiftBreakState(
        allowedMinutes: ApiModelParser.integer(json, 'allowedMinutes'),
        plannedMinutes: ApiModelParser.optionalInteger(json['plannedMinutes']),
        consumedSeconds: ApiModelParser.optionalInteger(
          json['consumedSeconds'],
        ),
        revision: ApiModelParser.optionalInteger(json['revision']),
        shiftEndsAt: ApiModelParser.optionalDate(json['shiftEndsAt']),
        lateDeductionMinutes:
            ApiModelParser.optionalInteger(json['lateDeductionMinutes']) ?? 0,
        reminderAt: ApiModelParser.optionalDate(json['reminderAt']),
        startedAt: ApiModelParser.optionalDate(json['startedAt']),
        endedAt: ApiModelParser.optionalDate(json['endedAt']),
      );
  DateTime? get endsAt {
    if (startedAt == null) return null;
    if (endedAt != null) return endedAt;
    final remaining = (allowedMinutes * 60 - (consumedSeconds ?? 0)).clamp(
      0,
      allowedMinutes * 60,
    );
    final deadline = startedAt!.add(Duration(seconds: remaining));
    return shiftEndsAt != null && shiftEndsAt!.isBefore(deadline)
        ? shiftEndsAt
        : deadline;
  }

  @override
  List<Object?> get props => [
    allowedMinutes,
    plannedMinutes,
    consumedSeconds,
    revision,
    shiftEndsAt,
    lateDeductionMinutes,
    reminderAt,
    startedAt,
    endedAt,
  ];
}
