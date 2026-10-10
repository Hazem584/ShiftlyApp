import 'dart:async';

import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';

abstract interface class FlexibleAttendanceHost {
  FlexibleAttendanceState get state;
  FeatureSessionScope? get scope;
  int get generation;
  bool get busy;
  Set<String> get consumed;
  FixedShiftRepository get repository;
  String newRequestId();
  DateTime now();
  void emitState(FlexibleAttendanceState state);
  bool current(FeatureSessionScope scope, int generation, int revision);
  int beginMutation();
  void release(FeatureSessionScope scope, int generation, int revision);
  Future<void> refreshAfterMutation(
    FeatureSessionScope scope,
    int generation,
    int revision,
  );
}
