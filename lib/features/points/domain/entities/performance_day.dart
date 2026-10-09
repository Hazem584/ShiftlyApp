import 'package:equatable/equatable.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/points/domain/entities/calendar_point_change.dart';
import 'package:shiftly/features/points/domain/entities/operational_date.dart';
import 'package:shiftly/features/points/domain/entities/point_enums.dart';

class PerformanceDay extends Equatable {
  const PerformanceDay({
    required this.date,
    required this.status,
    required this.extraEffort,
    required this.pointChanges,
    this.templateName,
    this.clockInAt,
    this.clockOutAt,
    this.workDurationMinutes,
    this.lateMinutes,
  });
  factory PerformanceDay.fromJson(Map<String, Object?> json) => PerformanceDay(
    date: OperationalDate.parse(ApiModelParser.string(json, 'operationalDate')),
    status: performanceStatusFromJson(json['status']),
    extraEffort: json['extraEffort'] == true,
    templateName: ApiModelParser.optionalString(json['templateName']),
    clockInAt: ApiModelParser.optionalDate(json['clockInAt']),
    clockOutAt: ApiModelParser.optionalDate(json['clockOutAt']),
    workDurationMinutes: ApiModelParser.optionalInteger(
      json['workDurationMinutes'],
    ),
    lateMinutes: ApiModelParser.optionalInteger(json['lateMinutes']),
    pointChanges: ApiModelParser.list(json['pointChanges'], 'pointChanges')
        .map(
          (item) => CalendarPointChange.fromJson(
            ApiModelParser.map(item, 'pointChange'),
          ),
        )
        .toList(growable: false),
  );
  final OperationalDate date;
  final PerformanceStatus status;
  final bool extraEffort;
  final String? templateName;
  final DateTime? clockInAt, clockOutAt;
  final int? workDurationMinutes, lateMinutes;
  final List<CalendarPointChange> pointChanges;
  @override
  List<Object?> get props => [
    date,
    status,
    extraEffort,
    templateName,
    clockInAt,
    clockOutAt,
    workDurationMinutes,
    lateMinutes,
    pointChanges,
  ];
}
