import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/features/employees/data/employee_repository.dart';

sealed class EmployeesState extends Equatable {
  const EmployeesState();
  @override
  List<Object?> get props => [];
}

final class EmployeesLoading extends EmployeesState {
  const EmployeesLoading();
}

final class EmployeesLoaded extends EmployeesState {
  const EmployeesLoaded({required this.employees, required this.query});
  final List<Employee> employees;
  final String query;
  @override
  List<Object?> get props => [employees, query];
}

final class EmployeesError extends EmployeesState {
  const EmployeesError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class EmployeesCubit extends Cubit<EmployeesState> {
  EmployeesCubit(this._repository) : super(const EmployeesLoading());
  final EmployeeRepository _repository;
  int _requestId = 0;

  Future<void> load({String query = ''}) async {
    final requestId = ++_requestId;
    try {
      final employees = await _repository.getEmployees(query: query);
      if (requestId == _requestId) {
        emit(EmployeesLoaded(employees: employees, query: query));
      }
    } catch (_) {
      if (requestId == _requestId) {
        emit(const EmployeesError('Unable to load employees.'));
      }
    }
  }

  Future<void> add(Employee employee) async {
    await _repository.addEmployee(employee);
    await load();
  }
}
