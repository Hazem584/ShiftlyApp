import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/features/profile/data/profile_image_picker.dart';
import 'package:shiftly/features/profile/data/profile_repository.dart';

part 'parts/profile_cubit/profile_action.dart';
part 'parts/profile_cubit/profile_operation_result.dart';
part 'parts/profile_cubit/profile_session_scope.dart';
part 'parts/profile_cubit/profile_state.dart';
part 'parts/profile_cubit/profile_loading.dart';
part 'parts/profile_cubit/profile_loaded.dart';
part 'parts/profile_cubit/profile_error.dart';
part 'parts/profile_cubit/profile_cubit.dart';
