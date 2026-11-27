import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_helpers.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_page_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_state.dart';

export 'leave_requests_state.dart';

class LeaveRequestsCubit extends LeaveRequestsPageCubit {
  LeaveRequestsCubit(super.repository, {super.onDashboardChanged});

  Future<LeaveMutationResult> review(
    String reqIdStr,
    LeaveReviewDecision decision, {
    String? rejectionReason,
  }) async {
    final activeScope = scope;
    if (activeScope == null) return LeaveMutationResult.failure;
    if (state.reviewingIds.contains(reqIdStr)) return LeaveMutationResult.busy;
    final reason = rejectionReason?.trim();
    final validation = validateLeaveReview(decision, reason);
    if (validation != null) {
      emit(state.copyWith(failure: validation));
      return LeaveMutationResult.failure;
    }
    final gen = generation;
    emit(
      state.copyWith(
        reviewingIds: {...state.reviewingIds, reqIdStr},
        clearFailure: true,
      ),
    );
    try {
      final record = await repository.review(
        activeScope.workspaceId,
        reqIdStr,
        decision,
        rejectionReason: reason,
      );
      if (!isScopeCurrent(activeScope, gen)) return LeaveMutationResult.stale;
      if (isInvalidLeaveReviewResponse(
        record,
        activeScope.workspaceId,
        reqIdStr,
        decision,
      )) {
        const failure = Failure(
          message: 'The server returned an invalid leave review response.',
          kind: FailureKind.server,
        );
        emit(applyLeaveReviewResult(state, reqIdStr, failure: failure));
        return LeaveMutationResult.failure;
      }
      emit(applyLeaveReviewResult(state, reqIdStr, record: record));
      onDashboardChanged?.call();
      return LeaveMutationResult.success;
    } catch (error) {
      if (!isScopeCurrent(activeScope, gen)) return LeaveMutationResult.stale;
      final failure = leaveFailure(
        error,
        'Unable to review the leave request.',
      );
      emit(applyLeaveReviewResult(state, reqIdStr, failure: failure));
      return LeaveMutationResult.failure;
    }
  }
}
