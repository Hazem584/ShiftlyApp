import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/fixed_shifts/data/fixed_shift_repository.dart';

enum FixedShiftMutationResult { success, failure, busy, stale }

class ManagerTemplatesState extends Equatable {
  const ManagerTemplatesState({
    this.loading = true,
    this.refreshing = false,
    this.templates = const [],
    this.includeArchived = false,
    this.saving = false,
    this.archivingId,
    this.failure,
  });
  final bool loading;
  final bool refreshing;
  final List<ShiftTemplate> templates;
  final bool includeArchived;
  final bool saving;
  final String? archivingId;
  final Failure? failure;

  ManagerTemplatesState copyWith({
    bool? loading,
    bool? refreshing,
    List<ShiftTemplate>? templates,
    bool? includeArchived,
    bool? saving,
    String? archivingId,
    bool clearArchiving = false,
    Failure? failure,
    bool clearFailure = false,
  }) => ManagerTemplatesState(
    loading: loading ?? this.loading,
    refreshing: refreshing ?? this.refreshing,
    templates: templates ?? this.templates,
    includeArchived: includeArchived ?? this.includeArchived,
    saving: saving ?? this.saving,
    archivingId: clearArchiving ? null : archivingId ?? this.archivingId,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    loading,
    refreshing,
    templates,
    includeArchived,
    saving,
    archivingId,
    failure?.message,
    failure?.requestId,
  ];
}

class ManagerTemplatesCubit extends Cubit<ManagerTemplatesState> {
  ManagerTemplatesCubit(this._repository)
    : super(const ManagerTemplatesState());
  final FixedShiftRepository _repository;
  FeatureSessionScope? _scope;
  var _generation = 0;
  Future<void>? _loadInFlight;

  void bindSession(FeatureSessionScope? scope) {
    final authorized = scope?.isManager == true ? scope : null;
    if (_scope == authorized) return;
    _scope = authorized;
    _generation++;
    _loadInFlight = null;
    emit(const ManagerTemplatesState());
    if (authorized != null) unawaited(load());
  }

  Future<void> load({bool refresh = false, bool? includeArchived}) {
    final running = _loadInFlight;
    if (running != null) return running;
    final future = _load(refresh: refresh, includeArchived: includeArchived);
    _loadInFlight = future;
    return future.whenComplete(() {
      if (identical(_loadInFlight, future)) _loadInFlight = null;
    });
  }

  Future<void> _load({required bool refresh, bool? includeArchived}) async {
    final scope = _scope;
    if (scope == null) return;
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
      if (!_current(scope, generation)) return;
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
      if (!_current(scope, generation)) return;
      final failure = _failure(error, 'Unable to load shift templates.');
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
    if (scope == null) return FixedShiftMutationResult.failure;
    if (state.saving) return FixedShiftMutationResult.busy;
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
      if (!_current(scope, generation)) return FixedShiftMutationResult.stale;
      if (record.workspaceId != scope.workspaceId) {
        throw const FormatException('Cross-workspace template response');
      }
      emit(state.copyWith(saving: false));
      await load(refresh: true);
      return FixedShiftMutationResult.success;
    } catch (error) {
      if (!_current(scope, generation)) return FixedShiftMutationResult.stale;
      emit(
        state.copyWith(
          saving: false,
          failure: _failure(error, 'Unable to save this template.'),
        ),
      );
      return FixedShiftMutationResult.failure;
    }
  }

  Future<FixedShiftMutationResult> archive(String templateId) async {
    final scope = _scope;
    if (scope == null) return FixedShiftMutationResult.failure;
    if (state.archivingId != null) return FixedShiftMutationResult.busy;
    final generation = _generation;
    emit(state.copyWith(archivingId: templateId, clearFailure: true));
    try {
      final record = await _repository.archiveTemplate(
        scope.workspaceId,
        templateId,
      );
      if (!_current(scope, generation)) return FixedShiftMutationResult.stale;
      if (record.workspaceId != scope.workspaceId || record.active) {
        throw const FormatException('Invalid archive response');
      }
      emit(state.copyWith(clearArchiving: true));
      await load(refresh: true);
      return FixedShiftMutationResult.success;
    } catch (error) {
      if (!_current(scope, generation)) return FixedShiftMutationResult.stale;
      emit(
        state.copyWith(
          clearArchiving: true,
          failure: _failure(error, 'Unable to archive this template.'),
        ),
      );
      return FixedShiftMutationResult.failure;
    }
  }

  bool _current(FeatureSessionScope scope, int generation) =>
      !isClosed && _scope == scope && _generation == generation;
}

class WorkPatternState extends Equatable {
  const WorkPatternState({
    this.loading = true,
    this.saving = false,
    this.history,
    this.failure,
  });
  final bool loading;
  final bool saving;
  final WorkPatternHistory? history;
  final Failure? failure;
  @override
  List<Object?> get props => [
    loading,
    saving,
    history?.current,
    history?.history,
    failure?.message,
    failure?.requestId,
  ];
}

class WorkPatternCubit extends Cubit<WorkPatternState> {
  WorkPatternCubit(this._repository) : super(const WorkPatternState());
  final FixedShiftRepository _repository;
  String? _workspaceId;
  String? _membershipId;
  var _generation = 0;

  Future<void> bind({
    required String workspaceId,
    required String membershipId,
  }) async {
    if (_workspaceId == workspaceId && _membershipId == membershipId) return;
    _workspaceId = workspaceId;
    _membershipId = membershipId;
    _generation++;
    emit(const WorkPatternState());
    await load();
  }

  Future<void> load({bool retain = false}) async {
    final workspaceId = _workspaceId;
    final membershipId = _membershipId;
    if (workspaceId == null || membershipId == null) return;
    final generation = _generation;
    if (!retain) emit(const WorkPatternState());
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
          history: retain ? state.history : null,
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

class FlexibleAttendanceState extends Equatable {
  const FlexibleAttendanceState({
    this.loading = true,
    this.refreshing = false,
    this.eligibility,
    this.current,
    this.templates = const [],
    this.submittingTemplateId,
    this.clockingOut = false,
    this.failure,
  });
  final bool loading;
  final bool refreshing;
  final TemplateEligibility? eligibility;
  final FlexibleAttendance? current;
  final List<ShiftTemplate> templates;
  final String? submittingTemplateId;
  final bool clockingOut;
  final Failure? failure;

  FlexibleAttendanceState copyWith({
    bool? loading,
    bool? refreshing,
    TemplateEligibility? eligibility,
    FlexibleAttendance? current,
    List<ShiftTemplate>? templates,
    bool clearCurrent = false,
    String? submittingTemplateId,
    bool clearSubmitting = false,
    bool? clockingOut,
    Failure? failure,
    bool clearFailure = false,
  }) => FlexibleAttendanceState(
    loading: loading ?? this.loading,
    refreshing: refreshing ?? this.refreshing,
    eligibility: eligibility ?? this.eligibility,
    current: clearCurrent ? null : current ?? this.current,
    templates: templates ?? this.templates,
    submittingTemplateId: clearSubmitting
        ? null
        : submittingTemplateId ?? this.submittingTemplateId,
    clockingOut: clockingOut ?? this.clockingOut,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    loading,
    refreshing,
    eligibility?.evaluatedAt,
    eligibility?.eligibleTemplates,
    current,
    templates,
    submittingTemplateId,
    clockingOut,
    failure?.message,
    failure?.requestId,
  ];
}

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
    var pending = await _repository.loadPendingClockIn();
    if (!_current(scope, generation)) return FixedShiftMutationResult.stale;
    if (pending == null ||
        !pending.matches(
          userId: scope.userId,
          workspaceId: scope.workspaceId,
          membershipId: scope.membershipId,
          templateId: occurrence.template.id,
        )) {
      pending = PendingClockIn(
        userId: scope.userId,
        workspaceId: scope.workspaceId,
        membershipId: scope.membershipId,
        templateId: occurrence.template.id,
        clientAttendanceId: _uuid(),
      );
      await _repository.savePendingClockIn(pending);
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
      await _repository.clearPendingClockIn();
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
      if (!ambiguous) await _repository.clearPendingClockIn();
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

Failure _failure(Object error, String fallback) =>
    error is ApiException ? error.toFailure() : Failure(message: fallback);

String _uuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((value) => value.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
