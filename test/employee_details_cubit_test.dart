import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/features/employees/data/mock_employee_repository.dart';
import 'package:shiftly/features/employees/presentation/cubit/employee_details_cubit.dart';

void main() {
  test('loads an employee by workspace membership id', () async {
    final cubit = EmployeeDetailsCubit(
      MockEmployeeRepository(delay: Duration.zero),
    );

    await cubit.load(workspaceId: 'workspace-1', membershipId: 'emp-1');

    expect(cubit.state, isA<EmployeeDetailsLoadedState>());
    expect((cubit.state as EmployeeDetailsLoadedState).employee.id, 'emp-1');
    await cubit.close();
  });

  test('exposes a safe error and never retains the prior employee', () async {
    final cubit = EmployeeDetailsCubit(
      MockEmployeeRepository(delay: Duration.zero, shouldFail: true),
    );

    await cubit.load(workspaceId: 'workspace-1', membershipId: 'missing');

    expect(cubit.state, isA<EmployeeDetailsErrorState>());
    expect(
      (cubit.state as EmployeeDetailsErrorState).message,
      'Unable to load this employee.',
    );
    await cubit.close();
  });
}
