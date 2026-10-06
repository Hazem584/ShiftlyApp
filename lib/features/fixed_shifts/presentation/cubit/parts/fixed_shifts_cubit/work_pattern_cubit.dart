part of '../../fixed_shifts_cubit.dart';

class WorkPatternCubit extends Cubit<WorkPatternState> {
  WorkPatternCubit(this._repository) : super(const WorkPatternState());
  final FixedShiftRepository _repository;
  String? _workspaceId;
  String? _membershipId;
  var _generation = 0;
  Future<void>? _loadInFlight;
  bool _refreshQueued = false;

  Future<void> bind({
    required String workspaceId,
    required String membershipId,
  }) async {
    if (_workspaceId == workspaceId && _membershipId == membershipId) return;
    _workspaceId = workspaceId;
    _membershipId = membershipId;
    _generation++;
    _loadInFlight = null;
    _refreshQueued = false;
    emit(const WorkPatternState());
    await load();
  }

  Future<void> load({bool retain = false}) {
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
    final workspaceId = _workspaceId;
    final membershipId = _membershipId;
    if (workspaceId == null || membershipId == null) return;
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
      );
      if (!_current(workspaceId, membershipId, generation)) return;
      if (value.history.any(
        (item) =>
            item.workspaceId != workspaceId ||
            item.employeeMembershipId != membershipId,
      )) {
        throw const FormatException('Cross-workspace work pattern response');
      }
      emit(WorkPatternState(loading: false, history: value));
    } catch (error) {
      if (!_current(workspaceId, membershipId, generation)) return;
      emit(
        WorkPatternState(
          loading: false,
          history: retain ? previous.history : null,
          failure: _failure(error, 'Unable to load work patterns.'),
        ),
      );
    }
  }

  Future<FixedShiftMutationResult> replace({
    required Set<int> weekdays,
    required String effectiveFrom,
  }) async {
    final workspaceId = _workspaceId;
    final membershipId = _membershipId;
    if (workspaceId == null || membershipId == null) {
      return FixedShiftMutationResult.failure;
    }
    if (state.saving) return FixedShiftMutationResult.busy;
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
      await _repository.replaceWorkPattern(
        workspaceId,
        membershipId,
        expectedWeekdays: weekdays.toList(),
        effectiveFrom: effectiveFrom,
      );
      if (!_current(workspaceId, membershipId, generation)) {
        return FixedShiftMutationResult.stale;
      }
      await load(retain: true);
      return FixedShiftMutationResult.success;
    } catch (error) {
      if (!_current(workspaceId, membershipId, generation)) {
        return FixedShiftMutationResult.stale;
      }
      emit(
        WorkPatternState(
          loading: false,
          history: state.history,
          failure: _failure(error, 'Unable to replace the work pattern.'),
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
