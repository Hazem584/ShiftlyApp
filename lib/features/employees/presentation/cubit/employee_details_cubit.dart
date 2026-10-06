import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/features/employees/data/employee_repository.dart';

part 'parts/employee_details_cubit/employee_details_state.dart';
part 'parts/employee_details_cubit/employee_details_loading_state.dart';
part 'parts/employee_details_cubit/employee_details_loaded_state.dart';
part 'parts/employee_details_cubit/employee_details_error_state.dart';
part 'parts/employee_details_cubit/employee_details_cubit.dart';
