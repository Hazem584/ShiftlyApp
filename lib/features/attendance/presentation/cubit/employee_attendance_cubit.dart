import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/attendance/data/attendance_repository.dart';

part 'parts/employee_attendance_cubit/employee_attendance_state.dart';
part 'parts/employee_attendance_cubit/employee_attendance_cubit.dart';
