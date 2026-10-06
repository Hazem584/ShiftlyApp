part of '../../fixed_shift_repository.dart';

class WorkPattern extends Equatable {
  const WorkPattern({
    required this.id,
    required this.workspaceId,
    required this.employeeMembershipId,
    required this.expectedWeekdays,
    required this.effectiveFrom,
    required this.createdAt,
    required this.updatedAt,
    this.effectiveTo,
  });

  final String id;
  final String workspaceId;
  final String employeeMembershipId;
  final List<int> expectedWeekdays;
  final String effectiveFrom;
  final String? effectiveTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory WorkPattern.fromJson(Map<String, Object?> json) {
    final weekdays = ApiModelParser.list(
      json['expectedWeekdays'],
      'expectedWeekdays',
    );
    if (weekdays.any((value) => value is! int || value < 0 || value > 6) ||
        weekdays.toSet().length != weekdays.length) {
      throw const FormatException('Invalid expectedWeekdays');
    }
    return WorkPattern(
      id: ApiModelParser.string(json, 'id'),
      workspaceId: ApiModelParser.string(json, 'workspaceId'),
      employeeMembershipId: ApiModelParser.string(json, 'employeeMembershipId'),
      expectedWeekdays: weekdays.cast<int>().toList(growable: false),
      effectiveFrom: _dateOnly(json, 'effectiveFrom'),
      effectiveTo: json['effectiveTo'] == null
          ? null
          : _dateOnly(json, 'effectiveTo'),
      createdAt: ApiModelParser.date(json, 'createdAt'),
      updatedAt: ApiModelParser.date(json, 'updatedAt'),
    );
  }

  @override
  List<Object?> get props => [
    id,
    workspaceId,
    employeeMembershipId,
    expectedWeekdays,
    effectiveFrom,
    effectiveTo,
    createdAt,
    updatedAt,
  ];
}
