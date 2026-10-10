import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

const reportScope = FeatureSessionScope(
  userId: 'user',
  workspaceId: 'workspace',
  membershipId: 'manager',
  timezone: 'Africa/Cairo',
  role: WorkspaceRole.manager,
  workspaceName: 'شركة الاختبار',
);

final reportRange = ReportRange(
  DateTime.utc(2026, 10),
  DateTime.utc(2026, 10, 31),
);

AttendanceRecordApi reportRecord({
  String id = 'record',
  String employeeId = 'employee',
  String name = 'أحمد',
  String workspaceId = 'workspace',
  AttendanceReviewStatus status = AttendanceReviewStatus.approved,
  int? work = 540,
  int late = 15,
  bool open = false,
  bool scheduled = true,
  bool extra = false,
  DateTime? clockIn,
}) {
  final start = clockIn ?? DateTime.utc(2026, 10, 1, 7);
  return AttendanceRecordApi(
    id: id,
    workspaceId: workspaceId,
    shiftId: null,
    employeeMembershipId: employeeId,
    clockInAt: start,
    clockOutAt: open ? null : start.add(Duration(minutes: work ?? 480)),
    scheduledStartAt: scheduled ? start : null,
    scheduledEndAt: scheduled ? start.add(const Duration(hours: 8)) : null,
    occurrenceKind: extra ? 'EXTRA' : 'BASELINE',
    reviewStatus: status,
    minutesLate: late,
    workedMinutes: work,
    createdAt: start,
    updatedAt: start,
    employee: ShiftEmployeeSummary(
      membershipId: employeeId,
      profileId: 'profile-$employeeId',
      role: WorkspaceRole.employee,
      membershipStatus: MembershipStatus.active,
      fullName: name,
    ),
  );
}

AttendanceReport fixtureReport({
  List<AttendanceRecordApi>? records,
  String workspaceId = 'workspace',
  ReportRange? range,
  List<ReportEmployee>? employees,
}) => AttendanceReport(
  workspaceId: workspaceId,
  workspaceName: 'شركة الاختبار',
  timezone: 'Africa/Cairo',
  range: range ?? reportRange,
  generatedAt: DateTime.utc(2026, 10, 10),
  employees:
      employees ??
      const [
        ReportEmployee('employee', 'أحمد'),
        ReportEmployee('second', 'منى'),
      ],
  records: records ?? [reportRecord()],
);

Employee rosterEmployee(String id) => Employee(
  id: id,
  fullName: 'Employee $id',
  phone: null,
  email: null,
  jobTitle: null,
  location: null,
  shift: null,
  startDate: null,
  employmentStatus: EmploymentStatus.active,
);
