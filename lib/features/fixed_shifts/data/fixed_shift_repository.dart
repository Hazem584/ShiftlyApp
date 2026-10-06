import 'package:equatable/equatable.dart';
import 'package:shiftly/core/network/api_model_parser.dart';

enum AttendanceClassification {
  early,
  onTime,
  late,
  unknown;

  static AttendanceClassification parse(Object? value) => switch (value) {
    'EARLY' => early,
    'ON_TIME' => onTime,
    'LATE' => late,
    _ => unknown,
  };

  bool get isActionable => this != unknown;
}

enum AttendanceSource {
  legacyShift,
  template,
  unknown;

  static AttendanceSource parse(Object? value) => switch (value) {
    'LEGACY_SHIFT' => legacyShift,
    'TEMPLATE' => template,
    _ => unknown,
  };
}

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
        startMinute > 1439 ||
        endMinute > 1439 ||
        graceMinutes > 1440 ||
        earlyMinutes > 1440 ||
        lateMinutes > 1440 ||
        minimumMinutes > 1440) {
      throw const FormatException('Invalid template values');
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

class ShiftTemplateInput {
  const ShiftTemplateInput({
    required this.name,
    required this.color,
    required this.startMinute,
    required this.endMinute,
    required this.graceMinutes,
    required this.allowedEarlyCheckInMinutes,
    required this.allowedLateCheckInMinutes,
    required this.minimumWorkMinutes,
    this.description,
  });

  final String name;
  final String? description;
  final String color;
  final int startMinute;
  final int endMinute;
  final int graceMinutes;
  final int allowedEarlyCheckInMinutes;
  final int allowedLateCheckInMinutes;
  final int minimumWorkMinutes;

  int get durationMinutes {
    final difference = endMinute - startMinute;
    return difference <= 0 ? difference + 1440 : difference;
  }

  String? validate() {
    if (name.trim().isEmpty || name.trim().length > 100) {
      return 'Enter a template name up to 100 characters.';
    }
    if (description != null && description!.trim().length > 1000) {
      return 'Description cannot exceed 1000 characters.';
    }
    if (!RegExp(r'^(#[0-9a-fA-F]{6}|[a-z][a-z0-9-]{0,39})$').hasMatch(color)) {
      return 'Choose a valid template color.';
    }
    if (startMinute < 0 ||
        startMinute > 1439 ||
        endMinute < 0 ||
        endMinute > 1439) {
      return 'Start and end times must be within one day.';
    }
    if ([
      graceMinutes,
      allowedEarlyCheckInMinutes,
      allowedLateCheckInMinutes,
      minimumWorkMinutes,
    ].any((value) => value < 0 || value > 1440)) {
      return 'Policy minutes must be between 0 and 1440.';
    }
    if (minimumWorkMinutes > durationMinutes) {
      return 'Minimum work time cannot exceed shift duration.';
    }
    return null;
  }

  Map<String, Object?> toJson() => {
    'name': name.trim(),
    if (description != null) 'description': description!.trim(),
    'color': color,
    'startMinute': startMinute,
    'endMinute': endMinute,
    'graceMinutes': graceMinutes,
    'allowedEarlyCheckInMinutes': allowedEarlyCheckInMinutes,
    'allowedLateCheckInMinutes': allowedLateCheckInMinutes,
    'minimumWorkMinutes': minimumWorkMinutes,
  };
}

class ShiftTemplatePage {
  const ShiftTemplatePage({required this.data, required this.pagination});
  final List<ShiftTemplate> data;
  final ApiPagination pagination;
}

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

class WorkPatternHistory {
  const WorkPatternHistory({required this.current, required this.history});
  final WorkPattern? current;
  final List<WorkPattern> history;
}

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

class TemplateEligibility {
  const TemplateEligibility({
    required this.workspaceId,
    required this.timezone,
    required this.evaluatedAt,
    required this.recommended,
    required this.eligibleTemplates,
  });
  final String workspaceId;
  final String timezone;
  final DateTime evaluatedAt;
  final EligibleShiftOccurrence? recommended;
  final List<EligibleShiftOccurrence> eligibleTemplates;
}

class PendingClockIn {
  const PendingClockIn({
    required this.userId,
    required this.workspaceId,
    required this.membershipId,
    required this.templateId,
    required this.clientAttendanceId,
  });
  final String userId;
  final String workspaceId;
  final String membershipId;
  final String templateId;
  final String clientAttendanceId;

  bool matches({
    required String userId,
    required String workspaceId,
    required String membershipId,
    required String templateId,
  }) =>
      this.userId == userId &&
      this.workspaceId == workspaceId &&
      this.membershipId == membershipId &&
      this.templateId == templateId;
}

class FlexibleAttendance extends Equatable {
  const FlexibleAttendance({
    required this.id,
    required this.workspaceId,
    required this.employeeMembershipId,
    required this.source,
    required this.clockInAt,
    required this.minutesLate,
    required this.createdAt,
    required this.updatedAt,
    this.shiftId,
    this.shiftTemplateId,
    this.clientAttendanceId,
    this.templateName,
    this.templateColor,
    this.workspaceTimezone,
    this.operationalDate,
    this.scheduledStartAt,
    this.scheduledEndAt,
    this.graceMinutesUsed,
    this.minimumWorkMinutesUsed,
    this.classification,
    this.clockOutAt,
    this.workedMinutes,
  });

  final String id;
  final String workspaceId;
  final String employeeMembershipId;
  final AttendanceSource source;
  final String? shiftId;
  final String? shiftTemplateId;
  final String? clientAttendanceId;
  final String? templateName;
  final String? templateColor;
  final String? workspaceTimezone;
  final String? operationalDate;
  final DateTime? scheduledStartAt;
  final DateTime? scheduledEndAt;
  final int? graceMinutesUsed;
  final int? minimumWorkMinutesUsed;
  final AttendanceClassification? classification;
  final DateTime clockInAt;
  final DateTime? clockOutAt;
  final int minutesLate;
  final int? workedMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOpen => clockOutAt == null;
  bool get isTemplate => source == AttendanceSource.template;
  bool get isActionable =>
      isTemplate &&
      classification != null &&
      classification != AttendanceClassification.unknown;

  factory FlexibleAttendance.fromJson(Map<String, Object?> json) {
    final template = ApiModelParser.optionalMap(
      json['shiftTemplate'],
      'shiftTemplate',
    );
    final source = AttendanceSource.parse(json['source']);
    final classification = json['clockInClassification'] == null
        ? null
        : AttendanceClassification.parse(json['clockInClassification']);
    final value = FlexibleAttendance(
      id: ApiModelParser.string(json, 'id'),
      workspaceId: ApiModelParser.string(json, 'workspaceId'),
      employeeMembershipId: ApiModelParser.string(json, 'employeeMembershipId'),
      source: source,
      shiftId: ApiModelParser.optionalString(json['shiftId']),
      shiftTemplateId: ApiModelParser.optionalString(json['shiftTemplateId']),
      clientAttendanceId: ApiModelParser.optionalString(
        json['clientAttendanceId'],
      ),
      templateName: ApiModelParser.optionalString(json['templateName']),
      templateColor: template == null
          ? null
          : ApiModelParser.optionalString(template['color']),
      workspaceTimezone: ApiModelParser.optionalString(
        json['workspaceTimezone'],
      ),
      operationalDate: json['operationalDate'] == null
          ? null
          : _operationalDate(json, 'operationalDate'),
      scheduledStartAt: ApiModelParser.optionalDate(json['scheduledStartAt']),
      scheduledEndAt: ApiModelParser.optionalDate(json['scheduledEndAt']),
      graceMinutesUsed: ApiModelParser.optionalInteger(
        json['graceMinutesUsed'],
      ),
      minimumWorkMinutesUsed: ApiModelParser.optionalInteger(
        json['minimumWorkMinutesUsed'],
      ),
      classification: classification,
      clockInAt: ApiModelParser.date(json, 'clockInAt'),
      clockOutAt: ApiModelParser.optionalDate(json['clockOutAt']),
      minutesLate: ApiModelParser.integer(json, 'minutesLate'),
      workedMinutes: ApiModelParser.optionalInteger(json['workedMinutes']),
      createdAt: ApiModelParser.date(json, 'createdAt'),
      updatedAt: ApiModelParser.date(json, 'updatedAt'),
    );
    if (source == AttendanceSource.template &&
        (value.shiftTemplateId == null ||
            value.templateName == null ||
            value.workspaceTimezone == null ||
            value.operationalDate == null ||
            value.scheduledStartAt == null ||
            value.scheduledEndAt == null ||
            value.classification == null)) {
      throw const FormatException('Incomplete template attendance');
    }
    if (source == AttendanceSource.legacyShift && value.shiftId == null) {
      throw const FormatException('Incomplete legacy attendance');
    }
    return value;
  }

  @override
  List<Object?> get props => [
    id,
    workspaceId,
    employeeMembershipId,
    source,
    shiftId,
    shiftTemplateId,
    clientAttendanceId,
    templateName,
    templateColor,
    workspaceTimezone,
    operationalDate,
    scheduledStartAt,
    scheduledEndAt,
    graceMinutesUsed,
    minimumWorkMinutesUsed,
    classification,
    clockInAt,
    clockOutAt,
    minutesLate,
    workedMinutes,
    createdAt,
    updatedAt,
  ];
}

abstract interface class FixedShiftRepository {
  Future<ShiftTemplatePage> listTemplates(
    String workspaceId, {
    bool includeArchived = false,
    int page = 1,
    int limit = 100,
  });
  Future<ShiftTemplate> getTemplate(String workspaceId, String templateId);
  Future<ShiftTemplate> createTemplate(
    String workspaceId,
    ShiftTemplateInput input,
  );
  Future<ShiftTemplate> updateTemplate(
    String workspaceId,
    String templateId,
    ShiftTemplateInput input,
  );
  Future<ShiftTemplate> archiveTemplate(String workspaceId, String templateId);
  Future<WorkPatternHistory> getWorkPatterns(
    String workspaceId,
    String membershipId,
  );
  Future<WorkPattern> replaceWorkPattern(
    String workspaceId,
    String membershipId, {
    required List<int> expectedWeekdays,
    required String effectiveFrom,
  });
  Future<ShiftTemplatePage> listMyTemplates(
    String workspaceId, {
    int page = 1,
    int limit = 100,
  });
  Future<TemplateEligibility> getEligibility(String workspaceId);
  Future<FlexibleAttendance?> getCurrentAttendance(String workspaceId);
  Future<FlexibleAttendance> flexibleClockIn({
    required String workspaceId,
    required String shiftTemplateId,
    required String clientAttendanceId,
  });
  Future<FlexibleAttendance> flexibleClockOut(String attendanceId);
  Future<PendingClockIn?> loadPendingClockIn();
  Future<void> savePendingClockIn(PendingClockIn value);
  Future<void> clearPendingClockIn();
}

String _dateOnly(Map<String, Object?> json, String key) {
  final value = ApiModelParser.string(json, key);
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
      DateTime.tryParse('${value}T00:00:00.000Z') == null) {
    throw FormatException('Invalid $key');
  }
  return value;
}

String _operationalDate(Map<String, Object?> json, String key) {
  final value = ApiModelParser.string(json, key);
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return value;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw FormatException('Invalid $key');
  return value.substring(0, 10);
}
