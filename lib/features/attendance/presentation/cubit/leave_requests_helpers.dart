import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_state.dart';

Failure leaveFailure(Object error, String fallback) =>
    error is ApiException ? error.toFailure() : Failure(message: fallback);

Failure? validateLeaveReview(LeaveReviewDecision decision, String? reason) {
  if (decision == LeaveReviewDecision.rejected &&
      (reason == null || reason.isEmpty)) {
    return const Failure(
      message: 'A rejection reason is required.',
      kind: FailureKind.validation,
    );
  }
  if ((reason?.length ?? 0) > 1000) {
    return const Failure(
      message: 'Rejection reason is too long.',
      kind: FailureKind.validation,
    );
  }
  return null;
}

bool isInvalidLeaveReviewResponse(
  LeaveRequestRecord record,
  String workspaceId,
  String requestId,
  LeaveReviewDecision decision,
) {
  final expected = decision == LeaveReviewDecision.approved
      ? LeaveRequestStatus.approved
      : LeaveRequestStatus.rejected;
  return record.workspaceId != workspaceId ||
      record.id != requestId ||
      record.status != expected;
}

LeaveRequestsState applyLeaveReviewResult(
  LeaveRequestsState state,
  String requestId, {
  LeaveRequestRecord? record,
  Failure? failure,
}) {
  final reviewing = {...state.reviewingIds}..remove(requestId);
  return state.copyWith(
    reviewingIds: reviewing,
    requests: record == null
        ? state.requests
        : state.requests
              .map((item) => item.id == requestId ? record : item)
              .toList(growable: false),
    selected: state.selected?.id == requestId ? record : state.selected,
    failure: failure,
  );
}
