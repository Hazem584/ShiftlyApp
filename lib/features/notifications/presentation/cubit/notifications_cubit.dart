import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/notifications/data/notification_repository.dart';

part 'parts/notifications_cubit/notification_mutation_result.dart';
part 'parts/notifications_cubit/notifications_state.dart';
part 'parts/notifications_cubit/notifications_cubit.dart';
