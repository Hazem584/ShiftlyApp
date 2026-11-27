import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/location/location_reader.dart';
import 'package:shiftly/core/location/selfie_capture.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shift_cubit_helpers.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/flexible_attendance_clock_out.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/flexible_attendance_host.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/flexible_attendance_loader.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/flexible_clock_in_controller.dart';

class FlexibleAttendanceCubit extends Cubit<FlexibleAttendanceState>
    implements FlexibleAttendanceHost {
  FlexibleAttendanceCubit(
    this._repository, {
    this.onAttendanceChanged,
    String Function()? uuid,
    DateTime Function()? now,
    AttendanceLocationReader? locationReader,
    AttendanceSelfieReader? selfieReader,
  }) : _now = now ?? DateTime.now,
       _uuid = uuid ?? fixedShiftUuid,
       _locationReader = locationReader ?? readDeviceAttendanceLocation,
       _selfieReader = selfieReader ?? captureFrontCameraSelfieBase64,
       super(const FlexibleAttendanceState());
  final FixedShiftRepository _repository;
  final FutureOr<void> Function()? onAttendanceChanged;
  final String Function() _uuid;
  final DateTime Function() _now;
  final AttendanceLocationReader _locationReader;
  final AttendanceSelfieReader _selfieReader;
  FeatureSessionScope? _scope;
  int _generation = 0, _revision = 0;
  bool _refreshQueued = false, _busy = false;
  Future<void>? _loadInFlight;
  final _consumed = <String>{};
  late final _clockIn = FlexibleClockInController(this);

  void bindSession(FeatureSessionScope? scope) {
    final valid = scope?.isEmployee == true ? scope : null;
    if (_scope == valid) return;
    _scope = valid;
    _generation++;
    _revision++;
    _refreshQueued = false;
    _busy = false;
    _consumed.clear();
    _loadInFlight = null;
    emit(const FlexibleAttendanceState());
    if (valid != null) unawaited(load());
  }

  Future<void> load({bool refresh = false}) {
    if (_scope == null) return Future.value();
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
    future = loadFlexibleAttendance(this, refresh: refresh, revision: revision)
        .whenComplete(() async {
          if (!identical(_loadInFlight, future)) return;
          _loadInFlight = null;
          if (_refreshQueued && !_busy) {
            _refreshQueued = false;
            await load(refresh: true);
          }
        });
    return _loadInFlight = future;
  }

  Future<FixedShiftMutationResult> clockOut() => performFlexibleClockOut(this);
  Future<FixedShiftMutationResult> clockIn(EligibleShiftOccurrence entry) =>
      _clockIn.clockIn(entry);
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
  Future<AttendanceLocationPoint?> readLocation({
    required bool requiredForPunch,
  }) async {
    final mode = state.eligibility?.geofenceMode ?? 'OFF';
    if (mode == 'OFF') return null;
    return _locationReader(
      requiredForPunch: requiredForPunch && mode == 'ENFORCE',
    );
  }

  @override
  Future<String?> readSelfie() async {
    final mode = state.eligibility?.selfieMode ?? 'OFF';
    if (mode == 'OFF') return null;
    return _selfieReader(requiredForPunch: mode == 'REQUIRED');
  }

  @override
  void emitState(FlexibleAttendanceState value) => emit(value);
  @override
  bool current(FeatureSessionScope scope, int gen, int rev) =>
      !isClosed && _scope == scope && _generation == gen && _revision == rev;
  @override
  int beginMutation() {
    _busy = true;
    _loadInFlight = null;
    _refreshQueued = false;
    return ++_revision;
  }

  @override
  void release(FeatureSessionScope scope, int gen, int rev) {
    if (!current(scope, gen, rev)) return;
    _busy = false;
    if (_refreshQueued) {
      _refreshQueued = false;
      unawaited(load(refresh: true));
    }
  }

  @override
  Future<void> refreshAfterMutation(
    FeatureSessionScope scope,
    int gen,
    int rev,
  ) => refreshAfterAttendanceMutation(
    this,
    scope,
    gen,
    rev,
    onAttendanceChanged,
  );
}
