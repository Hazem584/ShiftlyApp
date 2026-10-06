import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/dashboard/data/dashboard_repository.dart';

part 'parts/dashboard_cubit/dashboard_state.dart';
part 'parts/dashboard_cubit/dashboard_loading.dart';
part 'parts/dashboard_cubit/dashboard_loaded.dart';
part 'parts/dashboard_cubit/dashboard_error.dart';
part 'parts/dashboard_cubit/dashboard_cubit.dart';
