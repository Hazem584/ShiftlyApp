import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';

part 'parts/leave_requests_cubit/leave_mutation_result.dart';
part 'parts/leave_requests_cubit/leave_requests_state.dart';
part 'parts/leave_requests_cubit/leave_requests_cubit.dart';
