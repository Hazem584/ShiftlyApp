import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/models/shift.dart';
import 'package:shiftly/core/models/work_location.dart';
import 'package:shiftly/features/employees/data/mock_employee_seed.dart';
import 'package:shiftly/features/employees/data/mock_employee_seed_data.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';

class MockEmployeeRepository implements EmployeeRepository {
  MockEmployeeRepository({
    this.delay = const Duration(milliseconds: 350),
    this.shouldFail = false,
    List<Employee>? initialEmployees,
  }) : _employees = List.of(initialEmployees ?? seedMockEmployees());

  final Duration delay;
  final bool shouldFail;
  final List<Employee> _employees;

  @override
  List<Shift> get availableShifts => List.unmodifiable(mockShifts);

  @override
  List<WorkLocation> get availableLocations =>
      List.unmodifiable(mockWorkLocations);

  @override
  Future<List<Employee>> getEmployees({String query = ''}) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (shouldFail) throw Exception('Unable to load employees');
    final q = query.trim().toLowerCase();
    return List.unmodifiable(
      _employees.where(
        (e) => q.isEmpty || e.displayName.toLowerCase().contains(q),
      ),
    );
  }

  @override
  Future<Employee?> getEmployee(String id) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (shouldFail) throw Exception('Unable to load employee');
    return _employees.where((e) => e.id == id).firstOrNull;
  }

  @override
  Future<void> addEmployee(Employee employee) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (shouldFail) throw Exception('Unable to add employee');
    _employees.add(employee);
  }

  @override
  Future<EmployeePage> listEmployees({
    required String workspaceId,
    String search = '',
    EmployeeStatusFilter? status,
    int page = 1,
    int limit = 20,
  }) async => paginateMockEmployees(
    await getEmployees(query: search),
    status: status,
    page: page,
    limit: limit,
  );

  @override
  Future<Employee> getWorkspaceEmployee({
    required String workspaceId,
    required String membershipId,
  }) async {
    final employee = await getEmployee(membershipId);
    if (employee == null) throw Exception('Unable to load employee');
    return employee;
  }

  @override
  Future<Employee> setEmployeeStatus({
    required String workspaceId,
    required String membershipId,
    required EmployeeStatusFilter status,
  }) async {
    final index = _employees.indexWhere((item) => item.id == membershipId);
    if (index < 0) throw Exception('Unable to load employee');
    return _employees[index] = copyEmployeeWithStatus(
      _employees[index],
      status,
    );
  }

  @override
  Future<Employee> updateCompensation({
    required String workspaceId,
    required String membershipId,
    double? monthlySalary,
    double? hourlyRate,
  }) => getWorkspaceEmployee(
    workspaceId: workspaceId,
    membershipId: membershipId,
  );
}
