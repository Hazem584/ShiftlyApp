import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/extra_authorization.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/extra_shift_intent.dart';
import 'package:shiftly/features/fixed_shifts/domain/policies/confirmed_mutation_rejection.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_cubit_base.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_state.dart';

Future<bool> finalizeExtraSubmit(
  ExtraShiftsCubitBase cubit,
  FeatureSessionScope scope,
  int gen,
  int owner,
  ExtraShiftIntent intent,
  ExtraAuthorization canonical,
) async {
  var cleared = false;
  try {
    await cubit.repository.clearExtraIntent(scope, intent.encode());
    cleared = true;
  } catch (_) {}
  if (!cubit.ownsMutation(scope, gen, owner)) return true;
  cubit.emitState(
    ExtraShiftsState(
      busy: true,
      loading: false,
      page: cubit.state.page,
      canonical: canonical,
      intent: cleared ? null : intent,
      recoveryBlocked: !cleared,
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
}

Future<bool> handleExtraSubmitError(
  ExtraShiftsCubitBase cubit,
  FeatureSessionScope scope,
  int gen,
  int owner,
  ExtraShiftIntent intent,
  Object error,
) async {
  if (!cubit.ownsMutation(scope, gen, owner)) return false;
  var cleared = false;
  if (confirmedMutationRejection(error)) {
    try {
      await cubit.repository.clearExtraIntent(scope, intent.encode());
      cleared = true;
    } catch (_) {}
  }
  if (cubit.ownsMutation(scope, gen, owner)) {
    cubit.emitState(
      ExtraShiftsState(
        busy: true,
        loading: false,
        page: cubit.state.page,
        intent: cleared ? null : intent,
        canonical: cubit.state.canonical,
        recoveryBlocked: !cleared,
        failure: cubit.toFailure(
          error,
          'Could not save extra shift. Please review the details and try again.',
        ),
      ),
    );
  }
  return false;
}
