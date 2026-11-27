import 'dart:async';

import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/extra_authorization.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_actions.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_cubit_base.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_revoker.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_state.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_submitter.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_validator.dart';

class ExtraShiftsCubit extends ExtraShiftsCubitBase {
  ExtraShiftsCubit(super.repository, {super.onChanged});

  void bind(FeatureSessionScope? scope, String employeeId) {
    final valid = scope?.isManager == true ? scope : null;
    if (currentScope == valid && currentEmployeeId == employeeId) {
      return;
    }
    currentScope = valid;
    currentEmployeeId = employeeId;
    generation++;
    request++;
    isBusy = false;
    currentOwner = null;
    emit(const ExtraShiftsState());
    if (valid != null) {
      unawaited(load());
    }
  }

  Future<void> load({int page = 1}) => reloadPage(page: page);

  @override
  Future<void> reloadPage({int page = 1, int? owner}) =>
      loadExtraShiftsPage(this, page: page, owner: owner);

  Future<bool> create(
    Map<String, Object?> payload, {
    required bool actual,
  }) async {
    final scope = currentScope, employee = currentEmployeeId;
    if (scope == null ||
        employee == null ||
        isBusy ||
        state.loading ||
        state.recoveryBlocked) {
      return false;
    }
    final intent = buildExtraShiftIntent(employee, payload, actual: actual);
    if (intent == null) return false;
    return submitExtraShiftIntent(this, scope, intent);
  }

  Future<bool> recover() async {
    final scope = currentScope, intent = state.intent;
    if (scope == null || intent == null || isBusy) {
      return false;
    }
    return submitExtraShiftIntent(this, scope, intent);
  }

  Future<void> discardSavedIntent() async {
    final scope = currentScope, intent = state.intent;
    if (scope == null || intent == null || isBusy) return;
    try {
      await repository.clearExtraIntent(scope, intent.encode());
    } catch (_) {}
    emitState(
      ExtraShiftsState(
        busy: isBusy,
        loading: state.loading,
        page: state.page,
        canonical: state.canonical,
      ),
    );
  }

  Future<bool> revoke(ExtraAuthorization value) =>
      revokeExtraShiftAuthorization(this, value);
}
