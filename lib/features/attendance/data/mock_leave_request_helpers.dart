import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

List<LeaveRequestRecord> initialMockLeaveRequests() => [
  buildMockLeaveRequest(
    id: 'leave-1',
    employeeId: 'emp-1',
    name: 'Mariam Hassan',
    type: LeaveRequestType.annualLeave,
    reason: 'Family event outside the city.',
  ),
  buildMockLeaveRequest(
    id: 'leave-2',
    employeeId: 'emp-2',
    name: 'Omar Khaled',
    type: LeaveRequestType.earlyLeave,
    reason: 'Medical appointment at 3:30 PM.',
  ),
  buildMockLeaveRequest(
    id: 'leave-3',
    employeeId: 'emp-3',
    name: 'Nour Adel',
    status: LeaveRequestStatus.approved,
    reason: 'Personal day.',
  ),
];

LeaveRequestRecord buildMockLeaveRequest({
  required String id,
  required String employeeId,
  required String name,
  required String reason,
  LeaveRequestType type = LeaveRequestType.other,
  LeaveRequestStatus status = LeaveRequestStatus.pending,
  DateTime? startsAt,
  DateTime? endsAt,
  String workspaceId = 'preview-workspace',
}) => LeaveRequestRecord(
  id: id,
  workspaceId: workspaceId,
  employeeMembershipId: employeeId,
  type: type,
  status: status,
  startsAt: startsAt ?? DateTime.utc(2030, 1, 10),
  endsAt: endsAt ?? DateTime.utc(2030, 1, 11),
  reason: reason,
  reviewedAt: status == LeaveRequestStatus.pending
      ? null
      : DateTime.utc(2030, 1, 2),
  createdAt: DateTime.utc(2030, 1, 1),
  updatedAt: DateTime.utc(2030, 1, 1),
  employee: ShiftEmployeeSummary(
    membershipId: employeeId,
    profileId: 'profile-$employeeId',
    role: WorkspaceRole.employee,
    membershipStatus: MembershipStatus.active,
    fullName: name,
  ),
);

LeaveRequestRecord copyMockLeaveRequest(
  LeaveRequestRecord current, {
  required LeaveRequestStatus status,
  DateTime? reviewedAt,
  DateTime? cancelledAt,
  String? rejectionReason,
}) => LeaveRequestRecord(
  id: current.id,
  workspaceId: current.workspaceId,
  employeeMembershipId: current.employeeMembershipId,
  type: current.type,
  status: status,
  startsAt: current.startsAt,
  endsAt: current.endsAt,
  reason: current.reason,
  reviewedByMembershipId: reviewedAt == null ? null : 'manager-id',
  reviewedAt: reviewedAt,
  rejectionReason: rejectionReason,
  cancelledAt: cancelledAt,
  createdAt: current.createdAt,
  updatedAt: reviewedAt ?? cancelledAt ?? current.updatedAt,
  employee: current.employee,
);

ApiPagination mockLeavePagination(LeaveRequestQuery query, int total) =>
    ApiPagination(
      page: query.page,
      limit: query.limit,
      total: total,
      totalPages: total == 0 ? 0 : (total / query.limit).ceil(),
    );
