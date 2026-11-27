import 'package:shiftly/features/fixed_shifts/domain/entities/extra_shift_intent.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_cubit_base.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_state.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_validator.dart';

Future<void> loadExtraShiftsPage(
  ExtraShiftsCubitBase cubit, {
  int page = 1,
  int? owner,
}) async {
  final scope = cubit.currentScope, employee = cubit.currentEmployeeId;
  if (scope == null ||
      employee == null ||
      (cubit.isBusy && owner != cubit.currentOwner)) {
    return;
  }
  final gen = cubit.generation, req = ++cubit.request, prev = cubit.state;
  cubit.emitState(
    ExtraShiftsState(
      busy: cubit.isBusy,
      loading: true,
      page: prev.page,
      canonical: prev.canonical,
      intent: prev.intent,
    ),
  );
  try {
    final raw = await cubit.repository.readExtraIntent(scope);
    final intent = raw == null ? null : ExtraShiftIntent.decode(raw);
    if (!cubit.isValid(scope, gen) || req != cubit.request) return;
    cubit.emitState(
      ExtraShiftsState(
        busy: cubit.isBusy,
        loading: true,
        page: prev.page,
        intent: intent,
        canonical: prev.canonical,
      ),
    );
    final result = await cubit.repository.listExtras(
      scope.workspaceId,
      employee,
      page: page,
    );
    if (!cubit.isValid(scope, gen) || req != cubit.request) return;
    validateExtraPage(scope, employee, result);
    cubit.emitState(
      ExtraShiftsState(
        busy: cubit.isBusy,
        loading: false,
        page: result,
        intent: intent,
        recoveryBlocked: intent != null,
        canonical: prev.canonical,
      ),
    );
  } catch (error) {
    if (cubit.isValid(scope, gen) && req == cubit.request) {
      cubit.emitState(
        ExtraShiftsState(
          busy: cubit.isBusy,
          loading: false,
          page: prev.page,
          intent: cubit.state.intent,
          canonical: prev.canonical,
          failure: cubit.toFailure(
            error,
            'Unable to load extras or saved recovery. Retry before changing extras.',
          ),
        ),
      );
    }
  }
}
