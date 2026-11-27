import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_cancel_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_helpers.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_state.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_helpers.dart';

export 'employee_leave_requests_state.dart';

class EmployeeLeaveRequestsCubit extends EmployeeLeaveRequestsCancelCubit {
  EmployeeLeaveRequestsCubit(super.repository, {super.onDashboardChanged});

  static Failure? validate(CreateLeaveRequestInput input) =>
      validateLeaveRequestInput(input);

  Future<LeaveMutationResult> create(CreateLeaveRequestInput input) async {
    final activeScope = scope;
    if (activeScope == null) return LeaveMutationResult.failure;
    if (state.creating) return LeaveMutationResult.busy;
    final validation = validate(input);
    if (validation != null) {
      emit(state.copyWith(failure: validation));
      return LeaveMutationResult.failure;
    }
    final gen = generation;
    emit(state.copyWith(creating: true, clearFailure: true));
    try {
      final record = await repository.create(activeScope.workspaceId, input);
      if (!isScopeCurrent(activeScope, gen)) return LeaveMutationResult.stale;
      if (hasInvalidMineRecords([record], activeScope) ||
          record.status != LeaveRequestStatus.pending) {
        const failure = Failure(
          message: 'The server returned an invalid leave request.',
          kind: FailureKind.server,
        );
        emit(state.copyWith(creating: false, failure: failure));
        return LeaveMutationResult.failure;
      }
      final next = [
        record,
        ...state.requests.where((item) => item.id != record.id),
      ];
      emit(state.copyWith(requests: next, creating: false));
      onDashboardChanged?.call();
      return LeaveMutationResult.success;
    } catch (error) {
      if (!isScopeCurrent(activeScope, gen)) return LeaveMutationResult.stale;
      final failure = leaveFailure(
        error,
        'Unable to create the leave request.',
      );
      emit(state.copyWith(creating: false, failure: failure));
      return LeaveMutationResult.failure;
    }
  }
}
