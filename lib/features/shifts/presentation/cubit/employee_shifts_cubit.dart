import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/attendance/data/attendance_repository.dart';
import 'package:shiftly/features/fixed_shifts/data/fixed_shift_repository.dart';
import 'package:shiftly/features/shifts/data/shift_repository.dart';

part 'parts/employee_shifts_cubit/clock_mutation_result.dart';
part 'parts/employee_shifts_cubit/employee_shifts_state.dart';
part 'parts/employee_shifts_cubit/employee_shifts_cubit.dart';
