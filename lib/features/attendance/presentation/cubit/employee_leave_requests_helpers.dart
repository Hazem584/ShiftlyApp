import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_state.dart';

Failure? validateLeaveRequestInput(CreateLeaveRequestInput input) {
  if (input.type == LeaveRequestType.unknown) {
    return const Failure(
      message: 'Select a valid leave type.',
      kind: FailureKind.validation,
    );
  }
  if (!input.endsAt.isAfter(input.startsAt)) {
    return const Failure(
      message: 'Leave end must be after its start.',
      kind: FailureKind.validation,
    );
  }
  if (!input.startsAt.isAfter(DateTime.now().toUtc())) {
    return const Failure(
      message: 'Leave must start in the future.',
      kind: FailureKind.validation,
    );
  }
  if (input.endsAt.difference(input.startsAt) > const Duration(days: 365)) {
    return const Failure(
      message: 'Leave cannot be longer than 365 days.',
      kind: FailureKind.validation,
    );
  }
  final reason = input.reason.trim();
  if (reason.isEmpty || reason.length > 1000) {
    return const Failure(
      message: 'Enter a reason of up to 1000 characters.',
      kind: FailureKind.validation,
    );
  }
  return null;
}

EmployeeLeaveRequestsState applyLeaveCancelResult(
  EmployeeLeaveRequestsState state,
  String requestId, {
  LeaveRequestRecord? record,
  Failure? failure,
}) {
  final cancelling = {...state.cancellingIds}..remove(requestId);
  return state.copyWith(
    cancellingIds: cancelling,
    requests: record == null
        ? state.requests
        : state.requests
              .map((item) => item.id == requestId ? record : item)
              .toList(growable: false),
    selected: state.selected?.id == requestId ? record : state.selected,
    failure: failure,
  );
}
