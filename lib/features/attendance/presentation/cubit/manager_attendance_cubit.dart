import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/attendance/data/attendance_repository.dart';
import 'package:shiftly/features/shifts/data/shift_repository.dart';

part 'parts/manager_attendance_cubit/attendance_mutation_result.dart';
part 'parts/manager_attendance_cubit/manager_attendance_state.dart';
part 'parts/manager_attendance_cubit/manager_attendance_cubit.dart';
