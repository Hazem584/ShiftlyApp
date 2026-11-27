import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shift_cubit_helpers.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/work_pattern_replacer.dart';

class WorkPatternCubit extends Cubit<WorkPatternState> {
  WorkPatternCubit(this._repository, {this.onChanged})
    : super(const WorkPatternState());
  final FixedShiftRepository _repository;
  final FutureOr<void> Function()? onChanged;
  FeatureSessionScope? _scope;
  int _page = 1, _generation = 0;
  String? _workspaceId, _membershipId;
  Future<void>? _loadInFlight;
  bool _refreshQueued = false;

  Future<void> bind({
    FeatureSessionScope? scope,
    required String workspaceId,
    required String membershipId,
  }) async {
    if (_workspaceId == workspaceId &&
        _membershipId == membershipId &&
        _scope == scope) {
      return;
    }
    _scope = scope;
    _page = 1;
    _workspaceId = workspaceId;
    _membershipId = membershipId;
    _generation++;
    _loadInFlight = null;
    _refreshQueued = false;
    emit(const WorkPatternState());
    await load();
  }

  Future<void> load({bool retain = false, int? page}) {
    if (state.saving) return Future<void>.value();
    if (page != null) _page = page;
    final running = _loadInFlight;
    if (running != null) {
      _refreshQueued = true;
      return running;
    }
    final future = _load(retain: retain);
    _loadInFlight = future;
    return future.whenComplete(() {
      if (!identical(_loadInFlight, future)) return;
      _loadInFlight = null;
      if (_refreshQueued && _workspaceId != null && _membershipId != null) {
        _refreshQueued = false;
        unawaited(load(retain: true));
      }
    });
  }

  Future<void> _load({required bool retain}) async {
    final wId = _workspaceId, mId = _membershipId;
    if (wId == null ||
        mId == null ||
        _scope?.isManager != true ||
        _scope?.workspaceId != wId) {
      return;
    }
    final gen = _generation, prev = state;
    emit(
      !retain
          ? const WorkPatternState()
          : WorkPatternState(
              loading: true,
              history: prev.history,
              saving: prev.saving,
            ),
    );
    try {
      final value = await _repository.getWorkPatterns(wId, mId, page: _page);
      if (!_current(wId, mId, gen)) return;
      if ((value.current != null &&
              (value.current!.workspaceId != wId ||
                  value.current!.employeeMembershipId != mId)) ||
          value.history.any(
            (i) => i.workspaceId != wId || i.employeeMembershipId != mId,
          )) {
        throw const FormatException('Cross-workspace work pattern response');
      }
      emit(WorkPatternState(loading: false, history: value));
    } catch (error) {
      if (!_current(wId, mId, gen)) return;
      emit(
        WorkPatternState(
          loading: false,
          history: retain ? prev.history : null,
          failure: fixedShiftFailure(error, 'Unable to load work patterns.'),
        ),
      );
    }
  }

  Future<FixedShiftMutationResult> replace({
    required String shiftTemplateId,
    required Set<int> weekdays,
    required String effectiveFrom,
  }) => performWorkPatternReplace(
    repository: _repository,
    scope: _scope,
    workspaceId: _workspaceId,
    membershipId: _membershipId,
    generation: _generation,
    getState: () => state,
    emitState: emit,
    isCurrent: _current,
    onChanged: onChanged,
    reload: ({bool retain = false}) => load(retain: retain),
    shiftTemplateId: shiftTemplateId,
    weekdays: weekdays,
    effectiveFrom: effectiveFrom,
  );

  bool _current(String wId, String mId, int gen) =>
      !isClosed &&
      _workspaceId == wId &&
      _membershipId == mId &&
      _generation == gen;
}
