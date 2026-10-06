part of '../../leave_request_repository.dart';

abstract interface class LeaveRequestRepository {
  Future<LeaveRequestRecord> create(
    String workspaceId,
    CreateLeaveRequestInput input,
  );
  Future<LeaveRequestPage> listMine(
    String workspaceId,
    LeaveRequestQuery query,
  );
  Future<LeaveRequestRecord> getMine(String requestId);
  Future<LeaveRequestRecord> cancelMine(String requestId);
  Future<LeaveRequestPage> listWorkspace(
    String workspaceId,
    LeaveRequestQuery query,
  );
  Future<LeaveRequestRecord> getWorkspace(String workspaceId, String requestId);
  Future<LeaveRequestRecord> review(
    String workspaceId,
    String requestId,
    LeaveReviewDecision decision, {
    String? rejectionReason,
  });
}
