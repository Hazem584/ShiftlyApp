import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/extra_shift_intent.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_cubit_base.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_response_validator.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_state.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_submit_helpers.dart';

Future<bool> submitExtraShiftIntent(
  ExtraShiftsCubitBase cubit,
  FeatureSessionScope scope,
  ExtraShiftIntent intent,
) async {
  final owner = cubit.beginMutation(), gen = cubit.generation;
  cubit.emitState(
    ExtraShiftsState(
      loading: false,
      busy: true,
      intent: intent,
      page: cubit.state.page,
      canonical: cubit.state.canonical,
    ),
  );
  try {
    await cubit.repository.saveExtraIntent(scope, intent.encode());
    if (!cubit.ownsMutation(scope, gen, owner)) return false;
    final canonical = await cubit.repository.createExtra(
      scope.workspaceId,
      intent.membershipId,
      intent.payload,
      actual: intent.actual,
    );
    if (!cubit.ownsMutation(scope, gen, owner)) return false;
    validateExtraCreationResponse(scope, intent, canonical);
    cubit.emitState(
      ExtraShiftsState(
        busy: true,
        loading: false,
        page: cubit.state.page,
        canonical: canonical,
        intent: intent,
      ),
    );
    return await finalizeExtraSubmit(cubit, scope, gen, owner, intent, canonical);
  } catch (error) {
    return handleExtraSubmitError(cubit, scope, gen, owner, intent, error);
  } finally {
    cubit.releaseMutation(scope, gen, owner);
  }
}
