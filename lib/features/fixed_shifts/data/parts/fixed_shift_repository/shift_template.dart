part of '../../fixed_shift_repository.dart';

class ShiftTemplate extends Equatable {
  const ShiftTemplate({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.color,
    required this.startMinute,
    required this.endMinute,
    required this.graceMinutes,
    required this.allowedEarlyCheckInMinutes,
    required this.allowedLateCheckInMinutes,
    required this.minimumWorkMinutes,
    required this.active,
    required this.overnight,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.archivedAt,
  });

  final String id;
  final String workspaceId;
  final String name;
  final String? description;
  final String color;
  final int startMinute;
  final int endMinute;
  final int graceMinutes;
  final int allowedEarlyCheckInMinutes;
  final int allowedLateCheckInMinutes;
  final int minimumWorkMinutes;
  final bool active;
  final bool overnight;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get durationMinutes {
    final difference = endMinute - startMinute;
    return difference <= 0 ? difference + 1440 : difference;
  }

  factory ShiftTemplate.fromJson(Map<String, Object?> json) {
    final active = json['active'];
    final overnight = json['overnight'];
    if (active is! bool || overnight is! bool) {
      throw const FormatException('Invalid template state');
    }
    final color = ApiModelParser.string(json, 'color');
    final startMinute = ApiModelParser.integer(json, 'startMinute');
    final endMinute = ApiModelParser.integer(json, 'endMinute');
    final graceMinutes = ApiModelParser.integer(json, 'graceMinutes');
    final earlyMinutes = ApiModelParser.integer(
      json,
      'allowedEarlyCheckInMinutes',
    );
    final lateMinutes = ApiModelParser.integer(
      json,
      'allowedLateCheckInMinutes',
    );
    final minimumMinutes = ApiModelParser.integer(json, 'minimumWorkMinutes');
    if (!RegExp(r'^(#[0-9a-fA-F]{6}|[a-z][a-z0-9-]{0,39})$').hasMatch(color) ||
        startMinute < 0 ||
        startMinute > 1439 ||
        endMinute < 0 ||
        endMinute > 1439 ||
        graceMinutes < 0 ||
        graceMinutes > 1440 ||
        earlyMinutes < 0 ||
        earlyMinutes > 1440 ||
        lateMinutes < 0 ||
        lateMinutes > 1440 ||
        minimumMinutes < 0 ||
        minimumMinutes > 1440) {
      throw const FormatException('Invalid template values');
    }
    final duration = endMinute - startMinute <= 0
        ? endMinute - startMinute + 1440
        : endMinute - startMinute;
    if (minimumMinutes > duration) {
      throw const FormatException('Invalid minimum work duration');
    }
    return ShiftTemplate(
      id: ApiModelParser.string(json, 'id'),
      workspaceId: ApiModelParser.string(json, 'workspaceId'),
      name: ApiModelParser.string(json, 'name'),
      description: ApiModelParser.optionalString(json['description']),
      color: color,
      startMinute: startMinute,
      endMinute: endMinute,
      graceMinutes: graceMinutes,
      allowedEarlyCheckInMinutes: earlyMinutes,
      allowedLateCheckInMinutes: lateMinutes,
      minimumWorkMinutes: minimumMinutes,
      active: active,
      overnight: overnight,
      archivedAt: ApiModelParser.optionalDate(json['archivedAt']),
      createdAt: ApiModelParser.date(json, 'createdAt'),
      updatedAt: ApiModelParser.date(json, 'updatedAt'),
    );
  }

  @override
  List<Object?> get props => [
    id,
    workspaceId,
    name,
    description,
    color,
    startMinute,
    endMinute,
    graceMinutes,
    allowedEarlyCheckInMinutes,
    allowedLateCheckInMinutes,
    minimumWorkMinutes,
    active,
    overnight,
    archivedAt,
    createdAt,
    updatedAt,
  ];
}
