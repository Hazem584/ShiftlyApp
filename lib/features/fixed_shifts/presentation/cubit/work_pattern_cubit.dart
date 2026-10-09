import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/extra_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shift_cubit_helpers.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';

class WorkPatternCubit extends Cubit<WorkPatternState> {
  WorkPatternCubit(this._repository, {this.onChanged})
    : super(const WorkPatternState());
  final FixedShiftRepository _repository;
  final FutureOr<void> Function()? onChanged;
  FeatureSessionScope? _scope;
  int _page = 1;
  String? _workspaceId;
  String? _membershipId;
  var _generation = 0;
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
    if (state.saving) {
      return Future<void>.value();
    }
    if (page != null) {
      _page = page;
    }
    final running = _loadInFlight;
    if (running != null) {
      _refreshQueued = true;
      return running;
    }
    final future = _load(retain: retain);
    _loadInFlight = future;
    return future.whenComplete(() {
      if (!identical(_loadInFlight, future)) {
        return;
      }
      _loadInFlight = null;
      if (_refreshQueued && _workspaceId != null && _membershipId != null) {
        _refreshQueued = false;
        unawaited(load(retain: true));
      }
    });
  }

  Future<void> _load({required bool retain}) async {
    final workspaceId = _workspaceId;
    final membershipId = _membershipId;
    if (workspaceId == null ||
        membershipId == null ||
        _scope?.isManager != true ||
        _scope?.workspaceId != workspaceId) {
      return;
    }
    final generation = _generation;
    final previous = state;
    if (!retain) {
      emit(const WorkPatternState());
    } else {
      emit(
        WorkPatternState(
          loading: true,
          history: previous.history,
          saving: previous.saving,
        ),
      );
    }
    try {
      final value = await _repository.getWorkPatterns(
        workspaceId,
        membershipId,
        page: _page,
      );
      if (!_current(workspaceId, membershipId, generation)) {
        return;
      }
      if ((value.current != null &&
              (value.current!.workspaceId != workspaceId ||
                  value.current!.employeeMembershipId != membershipId)) ||
          value.history.any(
            (item) =>
                item.workspaceId != workspaceId ||
                item.employeeMembershipId != membershipId,
          )) {
        throw const FormatException('Cross-workspace work pattern response');
      }
      emit(WorkPatternState(loading: false, history: value));
    } catch (error) {
      if (!_current(workspaceId, membershipId, generation)) {
        return;
      }
      emit(
        WorkPatternState(
          loading: false,
          history: retain ? previous.history : null,
          failure: fixedShiftFailure(error, 'Unable to load work patterns.'),
        ),
      );
    }
  }

  Future<FixedShiftMutationResult> replace({
    required String shiftTemplateId,
    required Set<int> weekdays,
    required String effectiveFrom,
  }) async {
    final workspaceId = _workspaceId;
    final membershipId = _membershipId;
    if (workspaceId == null ||
        membershipId == null ||
        _scope?.isManager != true ||
        _scope?.workspaceId != workspaceId) {
      return FixedShiftMutationResult.failure;
    }
    if (state.saving || state.loading) {
      return FixedShiftMutationResult.busy;
    }
    if (weekdays.isEmpty || weekdays.any((value) => value < 0 || value > 6)) {
      emit(
        WorkPatternState(
          loading: false,
          history: state.history,
          failure: const Failure(
            message: 'Select at least one working day.',
            kind: FailureKind.validation,
          ),
        ),
      );
      return FixedShiftMutationResult.failure;
    }
    final generation = _generation;
    emit(
      WorkPatternState(loading: false, saving: true, history: state.history),
    );
    try {
      final ExtraShiftRepository? extraRepository =
          _repository is ExtraShiftRepository
          ? _repository as ExtraShiftRepository
          : null;
      if (extraRepository != null &&
          await extraRepository.readExtraIntent(_scope!) != null) {
        if (_current(workspaceId, membershipId, generation)) {
          emit(
            WorkPatternState(
              loading: false,
              history: state.history,
              failure: const Failure(
                message: 'Recover the saved extra operation before replacing an assignment.',
              ),
            ),
          );
        }
        return FixedShiftMutationResult.failure;
      }
      if (!_current(workspaceId, membershipId, generation)) {
        return FixedShiftMutationResult.stale;
      }
      final canonical = await _repository.replaceWorkPattern(
        workspaceId,
        membershipId,
        shiftTemplateId: shiftTemplateId,
        expectedWeekdays: weekdays.toList(),
        effectiveFrom: effectiveFrom,
      );
      if (!_current(workspaceId, membershipId, generation)) {
        return FixedShiftMutationResult.stale;
      }
      if (canonical.workspaceId != workspaceId ||
          canonical.employeeMembershipId != membershipId ||
          canonical.shiftTemplateId != shiftTemplateId) {
        throw const FormatException('Invalid assignment response');
      }
      final history = state.history;
      final localToday = _scope == null
          ? ''
          : WorkspaceTime.dateKey(DateTime.now().toUtc(), _scope!.timezone);
      emit(
        WorkPatternState(
          loading: false,
          history: WorkPatternHistory(
            current: canonical.effectiveFrom.compareTo(localToday) <= 0
                ? canonical
                : history?.current,
            history: [
              canonical,
              ...?history?.history.where((v) => v.id != canonical.id),
            ],
            pagination: history?.pagination,
          ),
        ),
      );
      try {
        await onChanged?.call();
      } catch (_) {}
      if (_current(workspaceId, membershipId, generation)) {
        await load(retain: true);
      }
      return FixedShiftMutationResult.success;
    } catch (error) {
      if (!_current(workspaceId, membershipId, generation)) {
        return FixedShiftMutationResult.stale;
      }
      emit(
        WorkPatternState(
          loading: false,
          history: state.history,
          failure: fixedShiftFailure(
            error,
            'Unable to replace the work pattern.',
          ),
        ),
      );
      return FixedShiftMutationResult.failure;
    }
  }

  bool _current(String workspaceId, String membershipId, int generation) =>
      !isClosed &&
      _workspaceId == workspaceId &&
      _membershipId == membershipId &&
      _generation == generation;
}
