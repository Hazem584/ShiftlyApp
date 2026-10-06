part of '../../fixed_shifts_cubit.dart';

class FlexibleAttendanceCubit extends Cubit<FlexibleAttendanceState> {
  FlexibleAttendanceCubit(
    this._repository, {
    this.onAttendanceChanged,
    String Function()? uuid,
  }) : _uuid = uuid ?? _uuidV4,
       super(const FlexibleAttendanceState());
  final FixedShiftRepository _repository;
  final FutureOr<void> Function()? onAttendanceChanged;
  final String Function() _uuid;
  FeatureSessionScope? _scope;
  var _generation = 0;
  Future<void>? _loadInFlight;

  void bindSession(FeatureSessionScope? scope) {
    final authorized = scope?.isEmployee == true ? scope : null;
    if (_scope == authorized) return;
    _scope = authorized;
    _generation++;
    _loadInFlight = null;
    emit(const FlexibleAttendanceState());
    if (authorized != null) unawaited(load());
  }

  Future<void> load({bool refresh = false}) {
    final running = _loadInFlight;
    if (running != null) return running;
    final future = _load(refresh: refresh);
    _loadInFlight = future;
    return future.whenComplete(() {
      if (identical(_loadInFlight, future)) _loadInFlight = null;
    });
  }

  Future<void> _load({required bool refresh}) async {
    final scope = _scope;
    if (scope == null) return;
    final generation = _generation;
    final previous = state;
    emit(
      refresh && (previous.current != null || previous.eligibility != null)
          ? previous.copyWith(refreshing: true, clearFailure: true)
          : const FlexibleAttendanceState(),
    );
    try {
      final values = await Future.wait<Object?>([
        _repository.getCurrentAttendance(scope.workspaceId),
        _repository.getEligibility(scope.workspaceId),
        _repository.listMyTemplates(scope.workspaceId),
      ]);
      if (!_current(scope, generation)) return;
      final current = values[0] as FlexibleAttendance?;
      final eligibility = values[1] as TemplateEligibility;
      final templates = (values[2] as ShiftTemplatePage).data;
      if ((current != null && current.workspaceId != scope.workspaceId) ||
          eligibility.workspaceId != scope.workspaceId ||
          templates.any((value) => value.workspaceId != scope.workspaceId)) {
        throw const FormatException('Cross-workspace attendance response');
      }
      emit(
        FlexibleAttendanceState(
          loading: false,
          current: current,
          eligibility: eligibility,
          templates: templates,
        ),
      );
    } catch (error) {
      if (!_current(scope, generation)) return;
      emit(
        previous.copyWith(
          loading: false,
          refreshing: false,
          failure: _failure(error, 'Unable to load fixed-shift attendance.'),
        ),
      );
    }
  }

  Future<FixedShiftMutationResult> clockIn(
    EligibleShiftOccurrence occurrence,
  ) async {
    final scope = _scope;
    if (scope == null || !occurrence.canClockIn) {
      return FixedShiftMutationResult.failure;
    }
    if (state.submittingTemplateId != null || state.current != null) {
      return FixedShiftMutationResult.busy;
    }
    final generation = _generation;
    var pending = await _repository.loadPendingClockIn(
      userId: scope.userId,
      workspaceId: scope.workspaceId,
      membershipId: scope.membershipId,
      templateId: occurrence.template.id,
    );
    if (!_current(scope, generation)) return FixedShiftMutationResult.stale;
    if (pending == null ||
        !pending.matches(
          userId: scope.userId,
          workspaceId: scope.workspaceId,
          membershipId: scope.membershipId,
          templateId: occurrence.template.id,
        )) {
      if (pending != null) await _repository.clearPendingClockIn(pending);
      if (!_current(scope, generation)) return FixedShiftMutationResult.stale;
      pending = PendingClockIn(
        userId: scope.userId,
        workspaceId: scope.workspaceId,
        membershipId: scope.membershipId,
        templateId: occurrence.template.id,
        clientAttendanceId: _uuid(),
      );
      await _repository.savePendingClockIn(pending);
      if (!_current(scope, generation)) return FixedShiftMutationResult.stale;
    }
    emit(
      state.copyWith(
        submittingTemplateId: occurrence.template.id,
        clearFailure: true,
      ),
    );
    try {
      final canonical = await _repository.flexibleClockIn(
        workspaceId: scope.workspaceId,
        shiftTemplateId: occurrence.template.id,
        clientAttendanceId: pending.clientAttendanceId,
      );
      if (!_current(scope, generation)) return FixedShiftMutationResult.stale;
      if (canonical.workspaceId != scope.workspaceId ||
          canonical.shiftTemplateId != occurrence.template.id) {
        throw const FormatException('Invalid clock-in response');
      }
      await _repository.clearPendingClockIn(pending);
      emit(state.copyWith(current: canonical, clearSubmitting: true));
      unawaited(_refreshAfterMutation());
      return FixedShiftMutationResult.success;
    } catch (error) {
      if (!_current(scope, generation)) return FixedShiftMutationResult.stale;
      final api = error is ApiException ? error : null;
      final ambiguous =
          api != null &&
          {
            FailureKind.network,
            FailureKind.timeout,
            FailureKind.cancelled,
            FailureKind.server,
          }.contains(api.kind);
      if (!ambiguous) await _repository.clearPendingClockIn(pending);
      emit(
        state.copyWith(
          clearSubmitting: true,
          failure: _failure(
            error,
            ambiguous
                ? 'Clock-in may have succeeded. Retry to safely confirm it.'
                : 'Unable to clock in.',
          ),
        ),
      );
      return FixedShiftMutationResult.failure;
    }
  }

  Future<FixedShiftMutationResult> clockOut() async {
    final scope = _scope;
    final active = state.current;
    if (scope == null || active == null || !active.isActionable) {
      return FixedShiftMutationResult.failure;
    }
    if (state.clockingOut) return FixedShiftMutationResult.busy;
    final generation = _generation;
    emit(state.copyWith(clockingOut: true, clearFailure: true));
    try {
      final canonical = await _repository.flexibleClockOut(active.id);
      if (!_current(scope, generation)) return FixedShiftMutationResult.stale;
      if (canonical.workspaceId != scope.workspaceId ||
          canonical.clockOutAt == null) {
        throw const FormatException('Invalid clock-out response');
      }
      emit(state.copyWith(current: canonical, clockingOut: false));
      unawaited(_refreshAfterMutation(clearCompleted: true));
      return FixedShiftMutationResult.success;
    } catch (error) {
      if (!_current(scope, generation)) return FixedShiftMutationResult.stale;
      emit(
        state.copyWith(
          clockingOut: false,
          failure: _failure(error, 'Unable to clock out.'),
        ),
      );
      return FixedShiftMutationResult.failure;
    }
  }

  Future<void> _refreshAfterMutation({bool clearCompleted = false}) async {
    try {
      await onAttendanceChanged?.call();
    } catch (_) {}
    final scope = _scope;
    if (scope == null) return;
    try {
      final current = await _repository.getCurrentAttendance(scope.workspaceId);
      final eligibility = await _repository.getEligibility(scope.workspaceId);
      final templates = await _repository.listMyTemplates(scope.workspaceId);
      if (isClosed || _scope != scope) return;
      emit(
        state.copyWith(
          current: current,
          clearCurrent: current == null && clearCompleted,
          eligibility: eligibility,
          templates: templates.data,
        ),
      );
    } catch (_) {
      // Canonical mutation success is retained when secondary refresh fails.
    }
  }

  bool _current(FeatureSessionScope scope, int generation) =>
      !isClosed && _scope == scope && _generation == generation;
}
