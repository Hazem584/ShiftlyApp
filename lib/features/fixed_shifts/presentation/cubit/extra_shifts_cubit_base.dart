import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/extra_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_state.dart';

abstract class ExtraShiftsCubitBase extends Cubit<ExtraShiftsState> {
  ExtraShiftsCubitBase(this.repository, {this.onChanged})
    : super(const ExtraShiftsState());
  final ExtraShiftRepository repository;
  final FutureOr<void> Function()? onChanged;
  FeatureSessionScope? currentScope;
  String? currentEmployeeId;
  int generation = 0, request = 0, mutation = 0;
  bool isBusy = false;
  int? currentOwner;

  bool isValid(FeatureSessionScope scope, int gen) =>
      !isClosed && currentScope == scope && generation == gen;
  bool ownsMutation(FeatureSessionScope scope, int gen, int owner) =>
      isValid(scope, gen) && currentOwner == owner;

  int beginMutation() {
    isBusy = true;
    request++;
    return currentOwner = ++mutation;
  }

  void releaseMutation(FeatureSessionScope scope, int gen, int owner) {
    if (!ownsMutation(scope, gen, owner)) return;
    currentOwner = null;
    isBusy = false;
    emit(
      ExtraShiftsState(
        loading: state.loading,
        page: state.page,
        intent: state.intent,
        canonical: state.canonical,
        recoveryBlocked: state.recoveryBlocked,
        failure: state.failure,
      ),
    );
  }

  void emitState(ExtraShiftsState value) => emit(value);
  Failure toFailure(Object error, String fallback) =>
      error is ApiException ? error.toFailure() : Failure(message: fallback);
  Future<void> reloadPage({int page = 1, int? owner});
}
