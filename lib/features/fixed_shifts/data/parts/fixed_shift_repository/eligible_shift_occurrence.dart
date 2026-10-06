part of '../../fixed_shift_repository.dart';

class EligibleShiftOccurrence extends Equatable {
  const EligibleShiftOccurrence({
    required this.template,
    required this.operationalDate,
    required this.scheduledStartAt,
    required this.scheduledEndAt,
    required this.checkInWindowStart,
    required this.checkInWindowEnd,
    required this.classification,
    required this.lateMinutes,
    required this.recommended,
  });

  final ShiftTemplate template;
  final String operationalDate;
  final DateTime scheduledStartAt;
  final DateTime scheduledEndAt;
  final DateTime checkInWindowStart;
  final DateTime checkInWindowEnd;
  final AttendanceClassification classification;
  final int lateMinutes;
  final bool recommended;

  bool get canClockIn => template.active && classification.isActionable;

  factory EligibleShiftOccurrence.fromJson(Map<String, Object?> json) {
    final recommended = json['recommended'];
    if (recommended is! bool) {
      throw const FormatException('Invalid recommended');
    }
    return EligibleShiftOccurrence(
      template: ShiftTemplate.fromJson(
        ApiModelParser.map(json['template'], 'template'),
      ),
      operationalDate: _dateOnly(json, 'operationalDate'),
      scheduledStartAt: ApiModelParser.date(json, 'scheduledStartAt'),
      scheduledEndAt: ApiModelParser.date(json, 'scheduledEndAt'),
      checkInWindowStart: ApiModelParser.date(json, 'checkInWindowStart'),
      checkInWindowEnd: ApiModelParser.date(json, 'checkInWindowEnd'),
      classification: AttendanceClassification.parse(
        json['expectedClockInClassification'],
      ),
      lateMinutes: ApiModelParser.integer(json, 'lateMinutes'),
      recommended: recommended,
    );
  }

  @override
  List<Object?> get props => [
    template,
    operationalDate,
    scheduledStartAt,
    scheduledEndAt,
    checkInWindowStart,
    checkInWindowEnd,
    classification,
    lateMinutes,
    recommended,
  ];
}
