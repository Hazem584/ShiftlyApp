import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/attendance/domain/entities/leave_request_status.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_helpers.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_page_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_state.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_helpers.dart';

abstract class EmployeeLeaveRequestsCancelCubit
    extends EmployeeLeaveRequestsPageCubit {
  EmployeeLeaveRequestsCancelCubit(
    super.repository, {
    super.onDashboardChanged,
  });

  Future<LeaveMutationResult> cancel(String reqIdStr) async {
    final activeScope = scope;
    if (activeScope == null) return LeaveMutationResult.failure;
    if (state.cancellingIds.contains(reqIdStr)) return LeaveMutationResult.busy;
    final gen = generation;
    emit(
      state.copyWith(
        cancellingIds: {...state.cancellingIds, reqIdStr},
        clearFailure: true,
      ),
    );
    try {
      final record = await repository.cancelMine(reqIdStr);
      if (!isScopeCurrent(activeScope, gen)) return LeaveMutationResult.stale;
      if (record.id != reqIdStr ||
          hasInvalidMineRecords([record], activeScope) ||
          record.status != LeaveRequestStatus.cancelled) {
        const failure = Failure(
          message: 'The server returned an invalid cancellation response.',
          kind: FailureKind.server,
        );
        emit(applyLeaveCancelResult(state, reqIdStr, failure: failure));
        return LeaveMutationResult.failure;
      }
      emit(applyLeaveCancelResult(state, reqIdStr, record: record));
      onDashboardChanged?.call();
      return LeaveMutationResult.success;
    } catch (error) {
      if (!isScopeCurrent(activeScope, gen)) return LeaveMutationResult.stale;
      final failure = leaveFailure(
        error,
        'Unable to cancel the leave request.',
      );
      emit(applyLeaveCancelResult(state, reqIdStr, failure: failure));
      return LeaveMutationResult.failure;
    }
  }
}
