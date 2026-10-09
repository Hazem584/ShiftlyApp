import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';

sealed class EmployeeDetailsState extends Equatable {
  const EmployeeDetailsState();
  @override
  List<Object?> get props => [];
}

final class EmployeeDetailsLoadingState extends EmployeeDetailsState {
  const EmployeeDetailsLoadingState();
}

final class EmployeeDetailsLoadedState extends EmployeeDetailsState {
  const EmployeeDetailsLoadedState(this.employee);
  final Employee employee;
  @override
  List<Object?> get props => [employee];
}

final class EmployeeDetailsErrorState extends EmployeeDetailsState {
  const EmployeeDetailsErrorState(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class EmployeeDetailsCubit extends Cubit<EmployeeDetailsState> {
  EmployeeDetailsCubit(this._repository)
    : super(const EmployeeDetailsLoadingState());
  final EmployeeRepository _repository;
  var _generation = 0;

  Future<void> load({
    required String workspaceId,
    required String membershipId,
    bool retain = false,
  }) async {
    final generation = ++_generation;
    if (!retain || state is! EmployeeDetailsLoadedState) {
      emit(const EmployeeDetailsLoadingState());
    }
    try {
      final employee = await _repository.getWorkspaceEmployee(
        workspaceId: workspaceId,
        membershipId: membershipId,
      );
      if (!isClosed && generation == _generation) {
        emit(EmployeeDetailsLoadedState(employee));
      }
    } catch (error) {
      if (!isClosed && generation == _generation) {
        emit(
          EmployeeDetailsErrorState(
            error is ApiException
                ? error.toFailure().message
                : 'Unable to load this employee.',
          ),
        );
      }
    }
  }
}
