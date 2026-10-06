part of '../../employees_cubit.dart';

final class EmployeesError extends EmployeesState {
  const EmployeesError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
