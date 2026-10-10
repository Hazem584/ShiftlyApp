import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/legacy_clock_in_review.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/legacy_clock_in_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shift_cubit_helpers.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';

import 'flexible_attendance_host.dart';
import 'flexible_clock_in_controller.dart';

class FlexibleAttendanceCubit extends Cubit<FlexibleAttendanceState>
    implements FlexibleAttendanceHost {
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
  int _revision = 0;
  bool _refreshQueued = false;
  Future<void>? _loadInFlight;
  bool _busy = false;
  final _consumed = <String>{};

  void bindSession(FeatureSessionScope? scope) {
    final valid = scope?.isEmployee == true ? scope : null;
    if (_scope == valid) {
      return;
    }
    _scope = valid;
    _generation++;
    _revision++;
    _refreshQueued = false;
    _busy = false;
    _consumed.clear();
    _loadInFlight = null;
    emit(const FlexibleAttendanceState());
    if (valid != null) {
      unawaited(load());
    }
  }

  bool _current(FeatureSessionScope scope, int generation, int revision) =>
      !isClosed &&
      _scope == scope &&
      _generation == generation &&
      _revision == revision;

  int _beginMutation() {
    _busy = true;
    _loadInFlight = null;
    _refreshQueued = false;
    return ++_revision;
  }

  void _release(FeatureSessionScope scope, int generation, int revision) {
    if (!_current(scope, generation, revision)) {
      return;
    }
    _busy = false;
    if (_refreshQueued) {
      _refreshQueued = false;
      unawaited(load(refresh: true));
    }
  }

  Future<void> load({bool refresh = false}) {
    if (_scope == null) {
      return Future.value();
    }
    if (_busy) {
      _refreshQueued = true;
      return Future.value();
    }
    if (_loadInFlight case final running?) {
      if (refresh && !_refreshQueued) {
        _refreshQueued = true;
        _revision++;
      }
      return running;
    }
    final revision = ++_revision;
    late final Future<void> future;
    future = _load(refresh: refresh, revision: revision).whenComplete(() async {
      if (!identical(_loadInFlight, future)) {
        return;
      }
      _loadInFlight = null;
      if (_refreshQueued && !_busy) {
        _refreshQueued = false;
        await load(refresh: true);
      }
    });
    _loadInFlight = future;
    return future;
  }

  Future<void> _load({required bool refresh, required int revision}) async {
    final scope = _scope;
    if (scope == null || _busy) {
      return;
    }
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
      if (!_current(scope, generation, revision)) {
        return;
      }
      if (restored != null &&
          (restored.workspaceId != scope.workspaceId ||
              restored.employeeMembershipId != scope.membershipId)) {
        throw const FormatException('Cross-scope attendance');
      }
      emit(
        state.copyWith(
          current: restored,
          clearCurrent: restored == null && state.current?.isOpen != false,
        ),
      );
      final pending = await _repository.loadPendingClockIn(
        userId: scope.userId,
        workspaceId: scope.workspaceId,
        membershipId: scope.membershipId,
        templateId: '',
      );
      if (!_current(scope, generation, revision)) {
        return;
      }
      emit(
        state.copyWith(
          recovery: pending,
          clearRecovery: pending == null,
          recoveryBlocked: pending != null,
        ),
      );
      final legacyRepository = _repository;
      final reviews = legacyRepository is LegacyClockInRepository
          ? await (legacyRepository as LegacyClockInRepository)
                .inspectLegacyClockIns(scope)
          : <LegacyClockInReview>[];
      if (!_current(scope, generation, revision)) {
        return;
      }
      emit(
        state.copyWith(
          legacyReviews: reviews,
          recoveryBlocked:
              pending != null || reviews.any((v) => v.requiresReview),
        ),
      );
      final values = await Future.wait<Object?>([
        Future.value(restored),
        _repository.getEligibility(scope.workspaceId),
        _repository.listMyTemplates(scope.workspaceId),
      ]);
      if (!_current(scope, generation, revision)) {
        return;
      }
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
          )) {
        throw const FormatException('Cross-scope attendance');
      }
      emit(
        FlexibleAttendanceState(
          loading: false,
          recovery: pending,
          legacyReviews: reviews,
          recoveryBlocked:
              pending != null || reviews.any((v) => v.requiresReview),
          current:
              current ??
              (state.current?.isOpen == false ? state.current : null),
          eligibility: eligibility,
          templates: templates,
        ),
      );
    } catch (error) {
      if (_current(scope, generation, revision)) {
        emit(
          state.copyWith(
            loading: false,
            refreshing: false,
            recoveryBlocked: true,
            failure: fixedShiftFailure(
              error,
              'Unable to load attendance. Restore access and refresh; saved operations are retained.',
            ),
          ),
        );
      }
    }
  }

  Future<FixedShiftMutationResult> clockOut() async {
    final scope = _scope;
    final active = state.current;
    if (scope == null ||
        active == null ||
        !active.isActionable ||
        !active.isOpen) {
      return FixedShiftMutationResult.failure;
    }
    if (_busy) {
      return FixedShiftMutationResult.busy;
    }
    final revision = _beginMutation();
    final generation = _generation;
    emit(
      state.copyWith(
        clockingOut: true,
        loading: false,
        refreshing: false,
        clearFailure: true,
      ),
    );
    try {
      final canonical = await _repository.flexibleClockOut(active.id);
      if (!_current(scope, generation, revision)) {
        return FixedShiftMutationResult.stale;
      }
      if (canonical.id != active.id ||
          canonical.workspaceId != scope.workspaceId ||
          canonical.employeeMembershipId != scope.membershipId ||
          canonical.clockOutAt == null) {
        throw const FormatException('Invalid clock-out response');
      }
      emit(
        state.copyWith(
          current: canonical,
          clockingOut: false,
          loading: false,
          refreshing: false,
          recoveryBlocked: true,
        ),
      );
      unawaited(_refreshAfterMutation(scope, generation, revision));
      return FixedShiftMutationResult.success;
    } catch (error) {
      if (_current(scope, generation, revision)) {
        emit(
          state.copyWith(
            clockingOut: false,
            failure: fixedShiftFailure(error, 'Unable to clock out.'),
          ),
        );
      }
      return FixedShiftMutationResult.failure;
    } finally {
      _release(scope, generation, revision);
    }
  }

  Future<void> _refreshAfterMutation(
    FeatureSessionScope scope,
    int generation,
    int revision,
  ) async {
    try {
      await onAttendanceChanged?.call();
    } catch (_) {}
    if (!_current(scope, generation, revision)) {
      return;
    }
    try {
      final eligibility = await _repository.getEligibility(scope.workspaceId);
      if (!_current(scope, generation, revision)) {
        return;
      }
      if (eligibility.workspaceId != scope.workspaceId) {
        throw const FormatException('Cross-scope eligibility');
      }
      // Keep the canonical mutation result, including completed/rejected evidence.
      emit(
        state.copyWith(
          eligibility: eligibility,
          recoveryBlocked: state.recovery != null || state.legacyReviewRequired,
        ),
      );
    } catch (_) {
      if (_current(scope, generation, revision)) {
        emit(
          state.copyWith(
            recoveryBlocked: true,
            failure: const Failure(
              message: 'Attendance saved. Schedule refresh failed; retry refresh before another clock-in.',
            ),
          ),
        );
      }
    }
  }

  late final _clockIn = FlexibleClockInController(this);
  Future<FixedShiftMutationResult> clockIn(
    EligibleShiftOccurrence occurrence,
  ) => _clockIn.clockIn(occurrence);
  Future<FixedShiftMutationResult> recoverClockIn() =>
      _clockIn.recoverClockIn();
  @override
  FeatureSessionScope? get scope => _scope;
  @override
  int get generation => _generation;
  @override
  bool get busy => _busy;
  @override
  Set<String> get consumed => _consumed;
  @override
  FixedShiftRepository get repository => _repository;
  @override
  String newRequestId() => _uuid();
  @override
  DateTime now() => _now();
  @override
  void emitState(FlexibleAttendanceState value) => emit(value);
  @override
  bool current(FeatureSessionScope scope, int generation, int revision) =>
      _current(scope, generation, revision);
  @override
  int beginMutation() => _beginMutation();
  @override
  void release(FeatureSessionScope scope, int generation, int revision) =>
      _release(scope, generation, revision);
  @override
  Future<void> refreshAfterMutation(
    FeatureSessionScope scope,
    int generation,
    int revision,
  ) => _refreshAfterMutation(scope, generation, revision);
}
