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
    ),
  );
  try {
    final raw = await cubit.repository.readExtraIntent(scope);
    if (raw != null) {
      try {
        await cubit.repository.clearExtraIntent(scope, raw);
      } catch (_) {}
    }
    if (!cubit.isValid(scope, gen) || req != cubit.request) return;
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
          canonical: prev.canonical,
          failure: cubit.toFailure(
            error,
            'Unable to load extra shifts. Please try again.',
          ),
        ),
      );
    }
  }
}
