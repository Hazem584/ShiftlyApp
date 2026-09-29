import 'package:equatable/equatable.dart';
import 'package:shiftly/core/network/api_model_parser.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';
import 'package:shiftly/features/shifts/data/shift_repository.dart';

sealed class DashboardData extends Equatable {
  const DashboardData({
    required this.date,
    required this.timezone,
    required this.generatedAt,
  });

  final String date;
  final String timezone;
  final DateTime generatedAt;
  bool get isEmpty;
}

class ManagerDashboardData extends DashboardData {
  const ManagerDashboardData({
    required super.date,
    required super.timezone,
    required super.generatedAt,
    required this.summary,
    required this.todayShifts,
    required this.pendingLeaveRequests,
  });

  final ManagerDashboardSummary summary;
  final List<DashboardShiftPreview> todayShifts;
  final List<DashboardLeavePreview> pendingLeaveRequests;

  factory ManagerDashboardData.fromJson(Map<String, Object?> json) =>
      ManagerDashboardData(
        date: _dateOnly(json, 'date'),
        timezone: ApiModelParser.string(json, 'timezone'),
        generatedAt: ApiModelParser.date(json, 'generatedAt'),
        summary: ManagerDashboardSummary.fromJson(
          ApiModelParser.map(json['summary'], 'summary'),
        ),
        todayShifts: ApiModelParser.list(json['todayShifts'], 'todayShifts')
            .map(
              (item) => DashboardShiftPreview.fromJson(
                ApiModelParser.map(item, 'todayShift'),
              ),
            )
            .toList(growable: false),
        pendingLeaveRequests:
            ApiModelParser.list(
                  json['pendingLeaveRequests'],
                  'pendingLeaveRequests',
                )
                .map(
                  (item) => DashboardLeavePreview.fromJson(
                    ApiModelParser.map(item, 'pendingLeaveRequest'),
                  ),
                )
                .toList(growable: false),
      );

  @override
  bool get isEmpty =>
      summary.totalEmployees == 0 &&
      todayShifts.isEmpty &&
      pendingLeaveRequests.isEmpty;

  @override
  List<Object?> get props => [
    date,
    timezone,
    generatedAt,
    summary,
    todayShifts,
    pendingLeaveRequests,
  ];
}

class ManagerDashboardSummary extends Equatable {
  const ManagerDashboardSummary({
    required this.totalEmployees,
    required this.scheduledToday,
    required this.clockedInNow,
    required this.completedToday,
    required this.lateToday,
    required this.missedToday,
    required this.onApprovedLeave,
    required this.pendingLeaveRequests,
    required this.unreadNotifications,
  });

  final int totalEmployees;
  final int scheduledToday;
  final int clockedInNow;
  final int completedToday;
  final int lateToday;
  final int missedToday;
  final int onApprovedLeave;
  final int pendingLeaveRequests;
  final int unreadNotifications;

  factory ManagerDashboardSummary.fromJson(
    Map<String, Object?> json,
  ) => ManagerDashboardSummary(
    totalEmployees: ApiModelParser.integer(json, 'totalEmployees'),
    scheduledToday: ApiModelParser.integer(json, 'scheduledToday'),
    clockedInNow: ApiModelParser.integer(json, 'clockedInNow'),
    completedToday: ApiModelParser.integer(json, 'completedToday'),
    lateToday: ApiModelParser.integer(json, 'lateToday'),
    missedToday: ApiModelParser.integer(json, 'missedToday'),
    onApprovedLeave: ApiModelParser.integer(json, 'onApprovedLeave'),
    pendingLeaveRequests: ApiModelParser.integer(json, 'pendingLeaveRequests'),
    unreadNotifications: ApiModelParser.integer(json, 'unreadNotifications'),
  );

  @override
  List<Object?> get props => [
    totalEmployees,
    scheduledToday,
    clockedInNow,
    completedToday,
    lateToday,
    missedToday,
    onApprovedLeave,
    pendingLeaveRequests,
    unreadNotifications,
  ];
}

class DashboardPerson extends Equatable {
  const DashboardPerson({
    required this.fullName,
    this.avatarUrl,
    this.jobTitle,
  });

  final String fullName;
  final String? avatarUrl;
  final String? jobTitle;

  factory DashboardPerson.fromJson(Map<String, Object?> json) =>
      DashboardPerson(
        fullName: ApiModelParser.string(json, 'fullName'),
        avatarUrl: ApiModelParser.optionalString(json['avatarUrl']),
        jobTitle: ApiModelParser.optionalString(json['jobTitle']),
      );

  @override
  List<Object?> get props => [fullName, avatarUrl, jobTitle];
}

enum DashboardAttendanceStatus {
  clockedIn,
  completed,
  unknown;

  static DashboardAttendanceStatus parse(Object? value) => switch (value) {
    'CLOCKED_IN' => clockedIn,
    'COMPLETED' => completed,
    _ => unknown,
  };
}

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
        id: _uuid(json, 'id'),
        status: DashboardAttendanceStatus.parse(json['status']),
        reviewStatus: AttendanceReviewStatus.parse(json['reviewStatus']),
        clockedInAt: ApiModelParser.date(json, 'clockedInAt'),
        clockedOutAt: ApiModelParser.optionalDate(json['clockedOutAt']),
        isLate: _boolean(json, 'isLate'),
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

class DashboardShiftPreview extends Equatable {
  const DashboardShiftPreview({
    required this.shiftId,
    required this.employeeMembershipId,
    required this.employee,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    this.attendance,
  });

  final String shiftId;
  final String employeeMembershipId;
  final DashboardPerson employee;
  final DateTime startsAt;
  final DateTime endsAt;
  final ShiftStatus status;
  final DashboardAttendance? attendance;

  factory DashboardShiftPreview.fromJson(Map<String, Object?> json) {
    final attendance = ApiModelParser.optionalMap(
      json['attendance'],
      'attendance',
    );
    return DashboardShiftPreview(
      shiftId: _uuid(json, 'shiftId'),
      employeeMembershipId: _uuid(json, 'employeeMembershipId'),
      employee: DashboardPerson.fromJson(
        ApiModelParser.map(json['employee'], 'employee'),
      ),
      startsAt: ApiModelParser.date(json, 'startsAt'),
      endsAt: ApiModelParser.date(json, 'endsAt'),
      status: ShiftStatus.parse(json['shiftStatus']),
      attendance: attendance == null
          ? null
          : DashboardAttendance.fromJson(attendance),
    );
  }

  @override
  List<Object?> get props => [
    shiftId,
    employeeMembershipId,
    employee,
    startsAt,
    endsAt,
    status,
    attendance,
  ];
}

class DashboardLeavePreview extends Equatable {
  const DashboardLeavePreview({
    required this.id,
    required this.type,
    required this.startsAt,
    required this.endsAt,
    required this.reason,
    required this.employeeMembershipId,
    required this.employee,
    required this.createdAt,
  });

  final String id;
  final LeaveRequestType type;
  final DateTime startsAt;
  final DateTime endsAt;
  final String reason;
  final String employeeMembershipId;
  final DashboardPerson employee;
  final DateTime createdAt;

  factory DashboardLeavePreview.fromJson(Map<String, Object?> json) {
    final employee = ApiModelParser.map(json['employee'], 'employee');
    return DashboardLeavePreview(
      id: _uuid(json, 'id'),
      type: LeaveRequestType.parse(json['type']),
      startsAt: ApiModelParser.date(json, 'startsAt'),
      endsAt: ApiModelParser.date(json, 'endsAt'),
      reason: ApiModelParser.string(json, 'reason'),
      employeeMembershipId: _uuid(employee, 'employeeMembershipId'),
      employee: DashboardPerson.fromJson(employee),
      createdAt: ApiModelParser.date(json, 'createdAt'),
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    startsAt,
    endsAt,
    reason,
    employeeMembershipId,
    employee,
    createdAt,
  ];
}

class EmployeeDashboardData extends DashboardData {
  const EmployeeDashboardData({
    required super.date,
    required super.timezone,
    required super.generatedAt,
    required this.employee,
    required this.summary,
    required this.recentLeaveRequests,
    this.todayShift,
    this.attendance,
    this.nextShift,
  });

  final EmployeeDashboardIdentity employee;
  final EmployeeDashboardShift? todayShift;
  final DashboardAttendance? attendance;
  final EmployeeDashboardShift? nextShift;
  final EmployeeDashboardSummary summary;
  final List<EmployeeDashboardLeave> recentLeaveRequests;

  factory EmployeeDashboardData.fromJson(Map<String, Object?> json) {
    final todayShift = ApiModelParser.optionalMap(
      json['todayShift'],
      'todayShift',
    );
    final attendance = ApiModelParser.optionalMap(
      json['attendance'],
      'attendance',
    );
    final nextShift = ApiModelParser.optionalMap(
      json['nextShift'],
      'nextShift',
    );
    return EmployeeDashboardData(
      date: _dateOnly(json, 'date'),
      timezone: ApiModelParser.string(json, 'timezone'),
      generatedAt: ApiModelParser.date(json, 'generatedAt'),
      employee: EmployeeDashboardIdentity.fromJson(
        ApiModelParser.map(json['employee'], 'employee'),
      ),
      todayShift: todayShift == null
          ? null
          : EmployeeDashboardShift.fromJson(todayShift),
      attendance: attendance == null
          ? null
          : DashboardAttendance.fromJson(attendance),
      nextShift: nextShift == null
          ? null
          : EmployeeDashboardShift.fromJson(nextShift),
      summary: EmployeeDashboardSummary.fromJson(
        ApiModelParser.map(json['summary'], 'summary'),
      ),
      recentLeaveRequests:
          ApiModelParser.list(
                json['recentLeaveRequests'],
                'recentLeaveRequests',
              )
              .map(
                (item) => EmployeeDashboardLeave.fromJson(
                  ApiModelParser.map(item, 'recentLeaveRequest'),
                ),
              )
              .toList(growable: false),
    );
  }

  @override
  bool get isEmpty =>
      todayShift == null &&
      nextShift == null &&
      recentLeaveRequests.isEmpty &&
      summary.pendingLeaveRequests == 0 &&
      summary.approvedLeaveRequests == 0;

  @override
  List<Object?> get props => [
    date,
    timezone,
    generatedAt,
    employee,
    todayShift,
    attendance,
    nextShift,
    summary,
    recentLeaveRequests,
  ];
}

class EmployeeDashboardIdentity extends DashboardPerson {
  const EmployeeDashboardIdentity({
    required this.membershipId,
    required super.fullName,
    super.avatarUrl,
    super.jobTitle,
  });

  final String membershipId;

  factory EmployeeDashboardIdentity.fromJson(Map<String, Object?> json) =>
      EmployeeDashboardIdentity(
        membershipId: _uuid(json, 'membershipId'),
        fullName: ApiModelParser.string(json, 'fullName'),
        avatarUrl: ApiModelParser.optionalString(json['avatarUrl']),
        jobTitle: ApiModelParser.optionalString(json['jobTitle']),
      );

  @override
  List<Object?> get props => [membershipId, ...super.props];
}

class EmployeeDashboardShift extends Equatable {
  const EmployeeDashboardShift({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    required this.status,
  });

  final String id;
  final DateTime startsAt;
  final DateTime endsAt;
  final ShiftStatus status;

  factory EmployeeDashboardShift.fromJson(Map<String, Object?> json) =>
      EmployeeDashboardShift(
        id: _uuid(json, 'id'),
        startsAt: ApiModelParser.date(json, 'startsAt'),
        endsAt: ApiModelParser.date(json, 'endsAt'),
        status: ShiftStatus.parse(json['status']),
      );

  @override
  List<Object?> get props => [id, startsAt, endsAt, status];
}

class EmployeeDashboardSummary extends Equatable {
  const EmployeeDashboardSummary({
    required this.pendingLeaveRequests,
    required this.approvedLeaveRequests,
    required this.unreadNotifications,
  });

  final int pendingLeaveRequests;
  final int approvedLeaveRequests;
  final int unreadNotifications;

  factory EmployeeDashboardSummary.fromJson(
    Map<String, Object?> json,
  ) => EmployeeDashboardSummary(
    pendingLeaveRequests: ApiModelParser.integer(json, 'pendingLeaveRequests'),
    approvedLeaveRequests: ApiModelParser.integer(
      json,
      'approvedLeaveRequests',
    ),
    unreadNotifications: ApiModelParser.integer(json, 'unreadNotifications'),
  );

  @override
  List<Object?> get props => [
    pendingLeaveRequests,
    approvedLeaveRequests,
    unreadNotifications,
  ];
}

class EmployeeDashboardLeave extends Equatable {
  const EmployeeDashboardLeave({
    required this.id,
    required this.type,
    required this.status,
    required this.startsAt,
    required this.endsAt,
    required this.reason,
    required this.createdAt,
    this.rejectionReason,
  });

  final String id;
  final LeaveRequestType type;
  final LeaveRequestStatus status;
  final DateTime startsAt;
  final DateTime endsAt;
  final String reason;
  final String? rejectionReason;
  final DateTime createdAt;

  factory EmployeeDashboardLeave.fromJson(Map<String, Object?> json) =>
      EmployeeDashboardLeave(
        id: _uuid(json, 'id'),
        type: LeaveRequestType.parse(json['type']),
        status: LeaveRequestStatus.parse(json['status']),
        startsAt: ApiModelParser.date(json, 'startsAt'),
        endsAt: ApiModelParser.date(json, 'endsAt'),
        reason: ApiModelParser.string(json, 'reason'),
        rejectionReason: ApiModelParser.optionalString(json['rejectionReason']),
        createdAt: ApiModelParser.date(json, 'createdAt'),
      );

  @override
  List<Object?> get props => [
    id,
    type,
    status,
    startsAt,
    endsAt,
    reason,
    rejectionReason,
    createdAt,
  ];
}

abstract interface class DashboardRepository {
  Future<ManagerDashboardData> getManagerDashboard(String workspaceId);
  Future<EmployeeDashboardData> getEmployeeDashboard(String workspaceId);
}

String _uuid(Map<String, Object?> json, String key) {
  final value = ApiModelParser.string(json, key);
  if (!RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(value)) {
    throw FormatException('Invalid $key');
  }
  return value;
}

bool _boolean(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! bool) throw FormatException('Invalid $key');
  return value;
}

String _dateOnly(Map<String, Object?> json, String key) {
  final value = ApiModelParser.string(json, key);
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) {
    throw FormatException('Invalid $key');
  }
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final parsed = DateTime.utc(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    throw FormatException('Invalid $key');
  }
  return value;
}
