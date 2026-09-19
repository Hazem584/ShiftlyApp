import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/employees/data/mock_employee_repository.dart';

void main() {
  test('DashboardCubit emits loaded data from its repository', () async {
    final employees = MockEmployeeRepository(delay: Duration.zero);
    final cubit = DashboardCubit(
      MockDashboardRepository(
        employeeRepository: employees,
        delay: Duration.zero,
      ),
    );
    addTearDown(cubit.close);
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([isA<DashboardLoading>(), isA<DashboardLoaded>()]),
    );
    await cubit.load();
    await expectation;
  });

  test('mock employee repository adds and searches an employee', () async {
    final repository = MockEmployeeRepository(delay: Duration.zero);
    final template = (await repository.getEmployees()).first;
    await repository.addEmployee(
      Employee(
        id: 'new-id',
        fullName: 'Test Teammate',
        phone: template.phone,
        email: 'test@shiftlab.com',
        jobTitle: template.jobTitle,
        location: template.location,
        shift: template.shift,
        startDate: template.startDate,
        employmentStatus: EmploymentStatus.active,
      ),
    );
    final results = await repository.getEmployees(query: 'teammate');
    expect(results.single.fullName, 'Test Teammate');
  });
}
