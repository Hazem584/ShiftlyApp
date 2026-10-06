import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/shifts/data/shift_repository.dart';

part 'parts/manager_shifts_cubit/shift_mutation_result.dart';
part 'parts/manager_shifts_cubit/manager_shifts_state.dart';
part 'parts/manager_shifts_cubit/manager_shifts_cubit.dart';

part 'parts/manager_shifts_cubit/private_first_or_null.dart';
