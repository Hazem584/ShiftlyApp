import 'package:shiftly/features/attendance/data/mock_leave_request_helpers.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';

class MockLeaveRequestRepository implements LeaveRequestRepository {
  MockLeaveRequestRepository({this.delay = Duration.zero})
    : _requests = initialMockLeaveRequests();

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
      pagination: mockLeavePagination(query, filtered.length),
    );
  }

  @override
  Future<LeaveRequestRecord> create(
    String workspaceId,
    CreateLeaveRequestInput input,
  ) async {
    await _wait();
    final created = buildMockLeaveRequest(
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
    final updated = copyMockLeaveRequest(
      _requests[index],
      status: status,
      reviewedAt: reviewedAt,
      cancelledAt: cancelledAt,
      rejectionReason: rejectionReason,
    );
    _requests[index] = updated;
    return updated;
  }
}
