import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'fixed_shifts_cubit.dart';

import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/error/failure.dart';

import 'fixed_shift_cubit_helpers.dart';
import '../../data/confirmed_mutation_rejection.dart';
import '../../data/fixed_shift_repository.dart';

class FlexibleAttendanceCubit extends Cubit<FlexibleAttendanceState> {
  FlexibleAttendanceCubit(
    this._repository, {
    this.onAttendanceChanged,
    String Function()? uuid,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       _uuid = uuid ?? fixedShiftUuid,
       super(const FlexibleAttendanceState());
  final FixedShiftRepository _repository;
  final FutureOr<void> Function()? onAttendanceChanged;
  final String Function() _uuid;
  final DateTime Function() _now;
  FeatureSessionScope? _scope;
  int _generation = 0;
  Future<void>? _loadInFlight;
  bool _busy = false;
  final _consumed = <String>{};

  void bindSession(FeatureSessionScope? scope) {
    final valid = scope?.isEmployee == true ? scope : null;
    if (_scope == valid) { return; }
    _scope = valid;
    _generation++;
    _busy = false;
    _consumed.clear();
    _loadInFlight = null;
    emit(const FlexibleAttendanceState());
    if (valid != null) { unawaited(load()); }
  }

  bool _current(FeatureSessionScope scope, int generation) =>
      !isClosed && _scope == scope && _generation == generation;
  Future<void> load({bool refresh = false}) {
    if (_loadInFlight case final running?) { return running; }
    final future = _load(refresh: refresh);
    _loadInFlight = future;
    return future.whenComplete(() {
      if (identical(_loadInFlight, future)) { _loadInFlight = null; }
    });
  }

  Future<void> _load({required bool refresh}) async {
    final scope = _scope;
    if (scope == null || _busy) { return; }
    final generation = _generation;
    final previous = state;
    emit(
      previous.copyWith(
        loading: previous.eligibility == null,
        refreshing: refresh,
        recoveryBlocked: true,
        clearFailure: true,
      ),
    );
    try {
      final restored = await _repository.getCurrentAttendance(
        scope.workspaceId,
      );
      if (!_current(scope, generation)) { return; }
      if (restored != null &&
          (restored.workspaceId != scope.workspaceId ||
              restored.employeeMembershipId != scope.membershipId))
        { throw const FormatException('Cross-scope attendance'); }
      emit(state.copyWith(current: restored, clearCurrent: restored == null));
      final pending = await _repository.loadPendingClockIn(
        userId: scope.userId,
        workspaceId: scope.workspaceId,
        membershipId: scope.membershipId,
        templateId: '',
      );
      if (!_current(scope, generation)) { return; }
      emit(
        state.copyWith(
          recovery: pending,
          clearRecovery: pending == null,
          recoveryBlocked: pending != null,
        ),
      );
      final values = await Future.wait<Object?>([
        Future.value(restored),
        _repository.getEligibility(scope.workspaceId),
        _repository.listMyTemplates(scope.workspaceId),
      ]);
      if (!_current(scope, generation)) { return; }
      final current = values[0] as FlexibleAttendance?;
      final eligibility = values[1] as TemplateEligibility;
      final templates = (values[2] as ShiftTemplatePage).data;
      if ((current != null &&
              (current.workspaceId != scope.workspaceId ||
                  current.employeeMembershipId != scope.membershipId)) ||
          eligibility.workspaceId != scope.workspaceId ||
          templates.any((v) => v.workspaceId != scope.workspaceId) ||
          eligibility.authorizedOccurrences.any(
            (v) => v.template.workspaceId != scope.workspaceId,
          ))
        { throw const FormatException('Cross-scope attendance'); }
      emit(
        FlexibleAttendanceState(
          loading: false,
          recovery: pending,
          recoveryBlocked: pending != null,
          current: current,
          eligibility: eligibility,
          templates: templates,
        ),
      );
    } catch (error) {
      if (_current(scope, generation))
        { emit(
          state.copyWith(
            loading: false,
            refreshing: false,
            recoveryBlocked: true,
            failure: fixedShiftFailure(
              error,
              'Unable to load attendance. An old saved operation may need manager review.',
            ),
          ),
        ); }
    }
  }

  Future<FixedShiftMutationResult> clockIn(
    EligibleShiftOccurrence occurrence,
  ) async {
    if (_busy) { return FixedShiftMutationResult.busy; }
    final scope = _scope;
    if (scope == null ||
        !occurrence.canClockIn ||
        state.recoveryBlocked ||
        state.loading ||
        state.refreshing ||
        state.failure != null ||
        !const {
          'ASSIGNED',
          'SHIFT_ASSIGNMENT_REQUIRED',
        }.contains(state.eligibility?.status) ||
        _consumed.contains(occurrence.identity))
      { return FixedShiftMutationResult.failure; }
    if (_busy ||
        state.current?.isOpen == true ||
        state.eligibility?.openAttendanceId != null)
      { return FixedShiftMutationResult.busy; }
    if (!(state.eligibility?.authorizedOccurrences.any(
          (v) =>
              v.identity == occurrence.identity &&
              v.canClockIn &&
              v.template.workspaceId == scope.workspaceId,
        ) ??
        false))
      { return FixedShiftMutationResult.failure; }
    _busy = true;
    final generation = _generation;
    emit(
      state.copyWith(
        submittingTemplateId: occurrence.template.id,
        clearFailure: true,
      ),
    );
    try {
      final stored = await _repository.loadPendingClockIn(
        userId: scope.userId,
        workspaceId: scope.workspaceId,
        membershipId: scope.membershipId,
        templateId: occurrence.template.id,
      );
      if (!_current(scope, generation)) { return FixedShiftMutationResult.stale; }
      if (stored != null) {
        emit(
          state.copyWith(
            recovery: stored,
            recoveryBlocked: true,
            clearSubmitting: true,
          ),
        );
        return FixedShiftMutationResult.failure;
      }
      final fresh = await _repository.getEligibility(scope.workspaceId);
      if (!_current(scope, generation)) { return FixedShiftMutationResult.stale; }
      if (fresh.workspaceId != scope.workspaceId ||
          fresh.openAttendanceId != null ||
          !fresh.authorizedOccurrences.any(
            (v) =>
                v.identity == occurrence.identity &&
                v.canClockIn &&
                v.template.workspaceId == scope.workspaceId,
          )) {
        emit(state.copyWith(eligibility: fresh, clearSubmitting: true));
        return FixedShiftMutationResult.failure;
      }
      final pending = PendingClockIn(
        userId: scope.userId,
        workspaceId: scope.workspaceId,
        membershipId: scope.membershipId,
        templateId: occurrence.template.id,
        clientAttendanceId: _uuid(),
        occurrenceKind: occurrence.occurrenceKind,
        assignmentId: occurrence.assignmentId,
        extraAuthorizationId: occurrence.extraAuthorizationId,
        operationalDate: occurrence.operationalDate,
      );
      await _repository.savePendingClockIn(pending);
      if (!_current(scope, generation)) { return FixedShiftMutationResult.stale; }
      emit(state.copyWith(recovery: pending, recoveryBlocked: true));
      return await _submitPending(scope, generation, pending);
    } catch (error) {
      if (_current(scope, generation))
        { emit(
          state.copyWith(
            clearSubmitting: true,
            recoveryBlocked: true,
            failure: fixedShiftFailure(
              error,
              'Clock-in recovery needs review. Refresh or contact your manager.',
            ),
          ),
        ); }
      return FixedShiftMutationResult.failure;
    } finally {
      if (_current(scope, generation)) { _busy = false; }
    }
  }

  Future<FixedShiftMutationResult> recoverClockIn() async {
    final scope = _scope;
    final pending = state.recovery;
    if (scope == null || pending == null || !pending.hasEvidence)
      { return FixedShiftMutationResult.failure; }
    if (_busy) { return FixedShiftMutationResult.busy; }
    _busy = true;
    final generation = _generation;
    emit(
      state.copyWith(
        submittingTemplateId: pending.templateId,
        clearFailure: true,
      ),
    );
    try {
      final canonical = await _repository.findPendingAttendance(pending);
      if (!_current(scope, generation)) { return FixedShiftMutationResult.stale; }
      if (canonical != null)
        { return await _submitPending(
          scope,
          generation,
          pending,
          recovered: canonical,
        ); }
      if (pending.occurrenceKind == 'BASELINE') {
        final fresh = await _repository.getEligibility(scope.workspaceId);
        if (!_current(scope, generation)) { return FixedShiftMutationResult.stale; }
        if (fresh.workspaceId != scope.workspaceId ||
            !fresh.authorizedOccurrences.any(
              (v) =>
                  pending.sameOccurrence(v) &&
                  v.canClockIn &&
                  v.template.workspaceId == scope.workspaceId &&
                  !_now().toUtc().isAfter(v.checkInWindowEnd),
            )) {
          emit(
            state.copyWith(
              clearSubmitting: true,
              failure: const Failure(
                message: 'The original baseline window is no longer available. The saved operation is retained for manager review; it cannot be replayed against a later occurrence.',
              ),
            ),
          );
          return FixedShiftMutationResult.failure;
        }
      }
      return await _submitPending(scope, generation, pending);
    } catch (error) {
      if (_current(scope, generation))
        { emit(
          state.copyWith(
            clearSubmitting: true,
            failure: fixedShiftFailure(
              error,
              'Unable to resolve saved clock-in. Retry recovery when access is restored.',
            ),
          ),
        ); }
      return FixedShiftMutationResult.failure;
    } finally {
      if (_current(scope, generation)) { _busy = false; }
    }
  }

  Future<FixedShiftMutationResult> _submitPending(
    FeatureSessionScope scope,
    int generation,
    PendingClockIn pending, {
    FlexibleAttendance? recovered,
  }) async {
    try {
      final canonical =
          recovered ??
          await _repository.flexibleClockIn(
            workspaceId: pending.workspaceId,
            shiftTemplateId: pending.templateId,
            clientAttendanceId: pending.clientAttendanceId,
            assignmentId: pending.assignmentId,
            extraAuthorizationId: pending.extraAuthorizationId,
          );
      if (!_current(scope, generation)) { return FixedShiftMutationResult.stale; }
      if (canonical.workspaceId != scope.workspaceId ||
          canonical.employeeMembershipId != scope.membershipId ||
          canonical.shiftTemplateId != pending.templateId ||
          canonical.clientAttendanceId != pending.clientAttendanceId ||
          canonical.occurrenceKind != pending.occurrenceKind ||
          canonical.assignmentId != pending.assignmentId ||
          canonical.extraAuthorizationId != pending.extraAuthorizationId ||
          canonical.operationalDate != pending.operationalDate)
        { throw const FormatException('Invalid canonical attendance'); }
      _consumed.add(
        '${pending.occurrenceKind}|${pending.templateId}|${pending.assignmentId}|${pending.extraAuthorizationId}|${pending.operationalDate}',
      );
      emit(
        state.copyWith(
          current: canonical,
          clearSubmitting: true,
          clearFailure: true,
        ),
      );
      try {
        await _repository.clearPendingClockIn(pending);
        if (_current(scope, generation))
          { emit(state.copyWith(clearRecovery: true, recoveryBlocked: false)); }
      } catch (_) {}
      if (_current(scope, generation))
        { unawaited(_refreshAfterMutation(scope, generation)); }
      return FixedShiftMutationResult.success;
    } catch (error) {
      if (!_current(scope, generation)) { return FixedShiftMutationResult.stale; }
      if (confirmedMutationRejection(error)) {
        var cleared = false;
        try {
          await _repository.clearPendingClockIn(pending);
          cleared = true;
        } catch (_) {}
        if (!_current(scope, generation)) { return FixedShiftMutationResult.stale; }
        emit(
          state.copyWith(
            clearRecovery: cleared,
            recoveryBlocked: true,
            clearSubmitting: true,
            failure: fixedShiftFailure(
              error,
              'Refresh before another clock-in.',
            ),
          ),
        );
      } else {
        emit(
          state.copyWith(
            recovery: pending,
            recoveryBlocked: true,
            clearSubmitting: true,
            failure: fixedShiftFailure(
              error,
              'Clock-in may have succeeded. Recover the saved operation before starting another shift.',
            ),
          ),
        );
      }
      return FixedShiftMutationResult.failure;
    }
  }

  Future<FixedShiftMutationResult> clockOut() async {
    final scope = _scope;
    final active = state.current;
    if (scope == null ||
        active == null ||
        !active.isActionable ||
        !active.isOpen)
      { return FixedShiftMutationResult.failure; }
    if (_busy) { return FixedShiftMutationResult.busy; }
    _busy = true;
    final generation = _generation;
    emit(state.copyWith(clockingOut: true, clearFailure: true));
    try {
      final canonical = await _repository.flexibleClockOut(active.id);
      if (!_current(scope, generation)) { return FixedShiftMutationResult.stale; }
      if (canonical.id != active.id ||
          canonical.workspaceId != scope.workspaceId ||
          canonical.employeeMembershipId != scope.membershipId ||
          canonical.clockOutAt == null)
        { throw const FormatException('Invalid clock-out response'); }
      emit(
        state.copyWith(
          current: canonical,
          clockingOut: false,
          recoveryBlocked: true,
        ),
      );
      unawaited(_refreshAfterMutation(scope, generation));
      return FixedShiftMutationResult.success;
    } catch (error) {
      if (_current(scope, generation))
        { emit(
          state.copyWith(
            clockingOut: false,
            failure: fixedShiftFailure(error, 'Unable to clock out.'),
          ),
        ); }
      return FixedShiftMutationResult.failure;
    } finally {
      if (_current(scope, generation)) { _busy = false; }
    }
  }

  Future<void> _refreshAfterMutation(
    FeatureSessionScope scope,
    int generation,
  ) async {
    try {
      await onAttendanceChanged?.call();
    } catch (_) {}
    if (!_current(scope, generation)) { return; }
    try {
      final eligibility = await _repository.getEligibility(scope.workspaceId);
      if (!_current(scope, generation)) { return; }
      if (eligibility.workspaceId != scope.workspaceId)
        { throw const FormatException('Cross-scope eligibility'); }
      // Keep the canonical mutation result, including completed/rejected evidence.
      emit(
        state.copyWith(
          eligibility: eligibility,
          recoveryBlocked: state.recovery != null,
        ),
      );
    } catch (_) {
      if (_current(scope, generation))
        { emit(
          state.copyWith(
            recoveryBlocked: true,
            failure: const Failure(
              message: 'Attendance saved. Schedule refresh failed; retry refresh before another clock-in.',
            ),
          ),
        ); }
    }
  }
}
