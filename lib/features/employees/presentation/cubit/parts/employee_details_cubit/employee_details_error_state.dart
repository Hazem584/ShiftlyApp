part of '../../employee_details_cubit.dart';

final class EmployeeDetailsErrorState extends EmployeeDetailsState {
  const EmployeeDetailsErrorState(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
