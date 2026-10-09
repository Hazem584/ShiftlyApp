import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

class MockLeaveRequestRepository implements LeaveRequestRepository {
  MockLeaveRequestRepository({this.delay = Duration.zero})
    : _requests = [
        _request(
          id: 'leave-1',
          employeeId: 'emp-1',
          name: 'Mariam Hassan',
          type: LeaveRequestType.annualLeave,
          reason: 'Family event outside the city.',
        ),
        _request(
          id: 'leave-2',
          employeeId: 'emp-2',
          name: 'Omar Khaled',
          type: LeaveRequestType.earlyLeave,
          reason: 'Medical appointment at 3:30 PM.',
        ),
        _request(
          id: 'leave-3',
          employeeId: 'emp-3',
          name: 'Nour Adel',
          status: LeaveRequestStatus.approved,
          reason: 'Personal day.',
        ),
      ];

  final Duration delay;
  final List<LeaveRequestRecord> _requests;

  Future<void> _wait() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
  }

  LeaveRequestPage _page(LeaveRequestQuery query) {
    final filtered = _requests
        .where((item) => query.status == null || item.status == query.status)
        .toList(growable: false);
    return LeaveRequestPage(
      data: filtered,
      pagination: _pagination(query, filtered.length),
    );
  }

  @override
  Future<LeaveRequestRecord> create(
    String workspaceId,
    CreateLeaveRequestInput input,
  ) async {
    await _wait();
    final created = _request(
      id: 'leave-created-${_requests.length}',
      employeeId: 'preview-employee',
      name: 'Preview Employee',
      type: input.type,
      reason: input.reason,
      startsAt: input.startsAt,
      endsAt: input.endsAt,
      workspaceId: workspaceId,
    );
    _requests.insert(0, created);
    return created;
  }

  @override
  Future<LeaveRequestPage> listMine(
    String workspaceId,
    LeaveRequestQuery query,
  ) async {
    await _wait();
    return _page(query);
  }

  @override
  Future<LeaveRequestPage> listWorkspace(
    String workspaceId,
    LeaveRequestQuery query,
  ) async {
    await _wait();
    return _page(query);
  }

  @override
  Future<LeaveRequestRecord> getMine(String requestId) async {
    await _wait();
    return _find(requestId);
  }

  @override
  Future<LeaveRequestRecord> getWorkspace(
    String workspaceId,
    String requestId,
  ) async {
    await _wait();
    return _find(requestId);
  }

  @override
  Future<LeaveRequestRecord> cancelMine(String requestId) async {
    await _wait();
    return _replace(
      requestId,
      status: LeaveRequestStatus.cancelled,
      cancelledAt: DateTime.utc(2030, 1, 2),
    );
  }

  @override
  Future<LeaveRequestRecord> review(
    String workspaceId,
    String requestId,
    LeaveReviewDecision decision, {
    String? rejectionReason,
  }) async {
    await _wait();
    return _replace(
      requestId,
      status: decision == LeaveReviewDecision.approved
          ? LeaveRequestStatus.approved
          : LeaveRequestStatus.rejected,
      reviewedAt: DateTime.utc(2030, 1, 2),
      rejectionReason: rejectionReason,
    );
  }

  LeaveRequestRecord _find(String id) =>
      _requests.firstWhere((request) => request.id == id);

  LeaveRequestRecord _replace(
    String id, {
    required LeaveRequestStatus status,
    DateTime? reviewedAt,
    DateTime? cancelledAt,
    String? rejectionReason,
  }) {
    final index = _requests.indexWhere((request) => request.id == id);
    if (index < 0) throw StateError('Request not found');
    final current = _requests[index];
    final updated = LeaveRequestRecord(
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
    _requests[index] = updated;
    return updated;
  }
}

LeaveRequestRecord _request({
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

ApiPagination _pagination(LeaveRequestQuery query, int total) => ApiPagination(
  page: query.page,
  limit: query.limit,
  total: total,
  totalPages: total == 0 ? 0 : (total / query.limit).ceil(),
);
