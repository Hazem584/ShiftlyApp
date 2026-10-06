import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/employees/data/employee_repository.dart';
import 'package:shiftly/features/invitations/data/invitation_repository.dart';

part 'parts/employees_cubit/employee_session_scope.dart';
part 'parts/employees_cubit/employee_operation_result.dart';
part 'parts/employees_cubit/employees_state.dart';
part 'parts/employees_cubit/employees_loading.dart';
part 'parts/employees_cubit/employees_loaded.dart';
part 'parts/employees_cubit/employees_error.dart';
part 'parts/employees_cubit/employees_cubit.dart';
