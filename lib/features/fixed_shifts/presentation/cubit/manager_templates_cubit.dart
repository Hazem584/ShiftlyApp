import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'fixed_shifts_cubit.dart';

import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/error/failure.dart';

import 'fixed_shift_cubit_helpers.dart';
import '../../data/fixed_shift_repository.dart';

class ManagerTemplatesCubit extends Cubit<ManagerTemplatesState> {
  ManagerTemplatesCubit(this._repository)
    : super(const ManagerTemplatesState());
  final FixedShiftRepository _repository;
  FeatureSessionScope? _scope;
  var _generation = 0;
  Future<void>? _loadInFlight;

  void bindSession(FeatureSessionScope? scope) {
    final authorized = scope?.isManager == true ? scope : null;
    if (_scope == authorized) { return; }
    _scope = authorized;
    _generation++;
    _loadInFlight = null;
    emit(const ManagerTemplatesState());
    if (authorized != null) { unawaited(load()); }
  }

  Future<void> load({bool refresh = false, bool? includeArchived}) {
    final running = _loadInFlight;
    if (running != null) { return running; }
    final future = _load(refresh: refresh, includeArchived: includeArchived);
    _loadInFlight = future;
    return future.whenComplete(() {
      if (identical(_loadInFlight, future)) { _loadInFlight = null; }
    });
  }

  Future<void> _load({required bool refresh, bool? includeArchived}) async {
    final scope = _scope;
    if (scope == null) { return; }
    final generation = _generation;
    final archived = includeArchived ?? state.includeArchived;
    final previous = state;
    emit(
      previous.templates.isNotEmpty && refresh
          ? previous.copyWith(
              refreshing: true,
              includeArchived: archived,
              clearFailure: true,
            )
          : ManagerTemplatesState(includeArchived: archived),
    );
    try {
      final page = await _repository.listTemplates(
        scope.workspaceId,
        includeArchived: archived,
      );
      if (!_current(scope, generation)) { return; }
      if (page.data.any((value) => value.workspaceId != scope.workspaceId)) {
        throw const FormatException('Cross-workspace template response');
      }
      emit(
        ManagerTemplatesState(
          loading: false,
          templates: page.data,
          includeArchived: archived,
        ),
      );
    } catch (error) {
      if (!_current(scope, generation)) { return; }
      final failure = fixedShiftFailure(
        error,
        'Unable to load shift templates.',
      );
      emit(
        previous.templates.isNotEmpty
            ? previous.copyWith(
                refreshing: false,
                includeArchived: archived,
                failure: failure,
              )
            : ManagerTemplatesState(
                loading: false,
                includeArchived: archived,
                failure: failure,
              ),
      );
    }
  }

  Future<FixedShiftMutationResult> save(
    ShiftTemplateInput input, {
    String? templateId,
  }) async {
    final scope = _scope;
    if (scope == null) { return FixedShiftMutationResult.failure; }
    if (state.saving) { return FixedShiftMutationResult.busy; }
    final message = input.validate();
    if (message != null) {
      emit(
        state.copyWith(
          failure: Failure(message: message, kind: FailureKind.validation),
        ),
      );
      return FixedShiftMutationResult.failure;
    }
    final generation = _generation;
    emit(state.copyWith(saving: true, clearFailure: true));
    try {
      final record = templateId == null
          ? await _repository.createTemplate(scope.workspaceId, input)
          : await _repository.updateTemplate(
              scope.workspaceId,
              templateId,
              input,
            );
      if (!_current(scope, generation)) { return FixedShiftMutationResult.stale; }
      if (record.workspaceId != scope.workspaceId) {
        throw const FormatException('Cross-workspace template response');
      }
      emit(state.copyWith(saving: false));
      await load(refresh: true);
      return FixedShiftMutationResult.success;
    } catch (error) {
      if (!_current(scope, generation)) { return FixedShiftMutationResult.stale; }
      emit(
        state.copyWith(
          saving: false,
          failure: fixedShiftFailure(error, 'Unable to save this template.'),
        ),
      );
      return FixedShiftMutationResult.failure;
    }
  }

  Future<FixedShiftMutationResult> archive(String templateId) async {
    final scope = _scope;
    if (scope == null) { return FixedShiftMutationResult.failure; }
    if (state.archivingId != null) { return FixedShiftMutationResult.busy; }
    final generation = _generation;
    emit(state.copyWith(archivingId: templateId, clearFailure: true));
    try {
      final record = await _repository.archiveTemplate(
        scope.workspaceId,
        templateId,
      );
      if (!_current(scope, generation)) { return FixedShiftMutationResult.stale; }
      if (record.workspaceId != scope.workspaceId || record.active) {
        throw const FormatException('Invalid archive response');
      }
      emit(state.copyWith(clearArchiving: true));
      await load(refresh: true);
      return FixedShiftMutationResult.success;
    } catch (error) {
      if (!_current(scope, generation)) { return FixedShiftMutationResult.stale; }
      emit(
        state.copyWith(
          clearArchiving: true,
          failure: fixedShiftFailure(error, 'Unable to archive this template.'),
        ),
      );
      return FixedShiftMutationResult.failure;
    }
  }

  bool _current(FeatureSessionScope scope, int generation) =>
      !isClosed && _scope == scope && _generation == generation;
}
