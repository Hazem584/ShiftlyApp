import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';

const dashboardWorkspaceId = 'c551356a-e456-4a3e-a49a-9dd0caa7e790';
const dashboardMembershipId = '040e52de-05b9-46b8-80ca-e7df3ef7444b';
const dashboardShiftId = '5b6d92e6-7054-413f-ab26-bff810f2ff61';
const dashboardAttendanceId = 'f65933d1-57ce-4f70-a28e-574bea205344';
const dashboardLeaveId = 'a5e624e8-ee45-4417-a932-5b48ad019656';

Map<String, Object?> managerDashboardJson({
  int totalEmployees = 12,
  int scheduledToday = 4,
  int clockedInNow = 2,
  int completedToday = 1,
  int lateToday = 1,
  int missedToday = 0,
  int onApprovedLeave = 1,
  int pendingLeaveRequests = 3,
  int unreadNotifications = 5,
  String timezone = 'Africa/Cairo',
  List<Object?>? todayShifts,
  List<Object?>? pendingLeaves,
}) => {
  'date': '2026-09-29',
  'timezone': timezone,
  'generatedAt': '2026-09-29T09:00:00.000Z',
  'summary': {
    'totalEmployees': totalEmployees,
    'scheduledToday': scheduledToday,
    'clockedInNow': clockedInNow,
    'completedToday': completedToday,
    'lateToday': lateToday,
    'missedToday': missedToday,
    'onApprovedLeave': onApprovedLeave,
    'pendingLeaveRequests': pendingLeaveRequests,
    'unreadNotifications': unreadNotifications,
  },
  'todayShifts': todayShifts ?? [dashboardShiftJson()],
  'pendingLeaveRequests': pendingLeaves ?? [dashboardLeaveJson()],
};

Map<String, Object?> dashboardShiftJson({String status = 'SCHEDULED'}) => {
  'shiftId': dashboardShiftId,
  'employeeMembershipId': dashboardMembershipId,
  'employee': {
    'fullName': 'Ahmed Mohamed',
    'avatarUrl': null,
    'jobTitle': 'Cashier',
  },
  'startsAt': '2026-09-29T06:00:00.000Z',
  'endsAt': '2026-09-29T14:00:00.000Z',
  'shiftStatus': status,
  'attendance': {
    'id': dashboardAttendanceId,
    'status': 'CLOCKED_IN',
    'reviewStatus': 'PENDING',
    'clockedInAt': '2026-09-29T06:05:00.000Z',
    'clockedOutAt': null,
    'isLate': true,
    'workedMinutes': null,
  },
};

Map<String, Object?> dashboardLeaveJson() => {
  'id': dashboardLeaveId,
  'type': 'ANNUAL_LEAVE',
  'startsAt': '2026-10-01T00:00:00.000Z',
  'endsAt': '2026-10-03T00:00:00.000Z',
  'reason': 'Family event',
  'employee': {
    'employeeMembershipId': dashboardMembershipId,
    'fullName': 'Ahmed Mohamed',
    'avatarUrl': null,
    'jobTitle': 'Cashier',
  },
  'createdAt': '2026-09-28T08:00:00.000Z',
};

Map<String, Object?> employeeDashboardJson({
  String membershipId = dashboardMembershipId,
  String timezone = 'Africa/Cairo',
  Object? todayShift = const _DefaultValue(),
  Object? attendance = const _DefaultValue(),
  Object? nextShift = const _DefaultValue(),
}) => {
  'date': '2026-09-29',
  'timezone': timezone,
  'generatedAt': '2026-09-29T09:00:00.000Z',
  'employee': {
    'membershipId': membershipId,
    'fullName': 'Ahmed Mohamed',
    'avatarUrl': null,
    'jobTitle': 'Cashier',
  },
  'todayShift': todayShift is _DefaultValue
      ? {
          'id': dashboardShiftId,
          'startsAt': '2026-09-29T06:00:00.000Z',
          'endsAt': '2026-09-29T14:00:00.000Z',
          'status': 'SCHEDULED',
        }
      : todayShift,
  'attendance': attendance is _DefaultValue
      ? {
          'id': dashboardAttendanceId,
          'status': 'CLOCKED_IN',
          'reviewStatus': 'PENDING',
          'clockedInAt': '2026-09-29T06:05:00.000Z',
          'clockedOutAt': null,
          'isLate': true,
          'workedMinutes': null,
        }
      : attendance,
  'nextShift': nextShift is _DefaultValue
      ? {
          'id': 'b5e624e8-ee45-4417-a932-5b48ad019657',
          'startsAt': '2026-09-30T06:00:00.000Z',
          'endsAt': '2026-09-30T14:00:00.000Z',
          'status': 'SCHEDULED',
        }
      : nextShift,
  'summary': {
    'pendingLeaveRequests': 1,
    'approvedLeaveRequests': 2,
    'unreadNotifications': 3,
  },
  'recentLeaveRequests': [
    {
      'id': dashboardLeaveId,
      'type': 'ANNUAL_LEAVE',
      'status': 'PENDING',
      'startsAt': '2026-10-01T00:00:00.000Z',
      'endsAt': '2026-10-03T00:00:00.000Z',
      'reason': 'Family event',
      'rejectionReason': null,
      'createdAt': '2026-09-28T08:00:00.000Z',
    },
  ],
};

ManagerDashboardData managerDashboard({String timezone = 'Africa/Cairo'}) =>
    ManagerDashboardData.fromJson(managerDashboardJson(timezone: timezone));

EmployeeDashboardData employeeDashboard({String timezone = 'Africa/Cairo'}) =>
    EmployeeDashboardData.fromJson(employeeDashboardJson(timezone: timezone));

class _DefaultValue {
  const _DefaultValue();
}
