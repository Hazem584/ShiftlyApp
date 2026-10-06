import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/fixed_shifts/data/fixed_shift_repository.dart';

part 'parts/fixed_shifts_cubit/fixed_shift_mutation_result.dart';
part 'parts/fixed_shifts_cubit/manager_templates_state.dart';
part 'parts/fixed_shifts_cubit/manager_templates_cubit.dart';
part 'parts/fixed_shifts_cubit/work_pattern_state.dart';
part 'parts/fixed_shifts_cubit/work_pattern_cubit.dart';
part 'parts/fixed_shifts_cubit/flexible_attendance_state.dart';
part 'parts/fixed_shifts_cubit/flexible_attendance_cubit.dart';

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
