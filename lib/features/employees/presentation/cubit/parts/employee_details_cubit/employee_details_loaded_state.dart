part of '../../employee_details_cubit.dart';

final class EmployeeDetailsLoadedState extends EmployeeDetailsState {
  const EmployeeDetailsLoadedState(this.employee);
  final Employee employee;
  @override
  List<Object?> get props => [employee];
}
