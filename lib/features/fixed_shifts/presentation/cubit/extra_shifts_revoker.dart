import 'package:shiftly/features/fixed_shifts/domain/entities/extra_authorization.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_cubit_base.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_response_validator.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_state.dart';

Future<bool> revokeExtraShiftAuthorization(
  ExtraShiftsCubitBase cubit,
  ExtraAuthorization value,
) async {
  final scope = cubit.currentScope, employee = cubit.currentEmployeeId;
  if (scope == null ||
      employee == null ||
      cubit.isBusy ||
      cubit.state.loading ||
      cubit.state.recoveryBlocked ||
      !value.canRevoke ||
      value.fields['employeeMembershipId'] != employee ||
      value.fields['workspaceId'] != scope.workspaceId) {
    return false;
  }
  final owner = cubit.beginMutation(), gen = cubit.generation;
  cubit.emitState(
    ExtraShiftsState(
      loading: false,
      busy: true,
      page: cubit.state.page,
      canonical: cubit.state.canonical,
      recoveryBlocked: false,
    ),
  );
  try {
    final canonical = await cubit.repository.revokeExtra(
      scope.workspaceId,
      employee,
      value.id,
    );
    if (!cubit.ownsMutation(scope, gen, owner)) return false;
    validateExtraRevocationResponse(scope, employee, value, canonical);
    cubit.emitState(
      ExtraShiftsState(
        busy: true,
        loading: false,
        canonical: canonical,
        page: cubit.state.page,
        recoveryBlocked: false,
      ),
    );
    try {
      await cubit.onChanged?.call();
    } catch (_) {}
    if (cubit.ownsMutation(scope, gen, owner)) {
      await cubit.reloadPage(
        page: cubit.state.page?.pagination.page ?? 1,
        owner: owner,
      );
    }
    return true;
  } catch (error) {
    if (cubit.ownsMutation(scope, gen, owner)) {
      cubit.emitState(
        ExtraShiftsState(
          busy: true,
          loading: false,
          page: cubit.state.page,
          canonical: cubit.state.canonical,
          failure: cubit.toFailure(
            error,
            'Unable to confirm revocation. Refresh its status before retrying.',
          ),
        ),
      );
    }
    return false;
  } finally {
    cubit.releaseMutation(scope, gen, owner);
  }
}
