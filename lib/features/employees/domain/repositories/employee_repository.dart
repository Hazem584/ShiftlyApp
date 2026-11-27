import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/models/shift.dart';
import 'package:shiftly/core/models/work_location.dart';
import 'package:shiftly/features/employees/domain/entities/employee_models.dart';

export 'package:shiftly/features/employees/domain/entities/employee_models.dart';

abstract interface class EmployeeRepository {
  Future<List<Employee>> getEmployees({String query = ''});
  Future<Employee?> getEmployee(String id);
  Future<void> addEmployee(Employee employee);
  Future<EmployeePage> listEmployees({
    required String workspaceId,
    String search = '',
    EmployeeStatusFilter? status,
    int page = 1,
    int limit = 20,
  });
  Future<Employee> getWorkspaceEmployee({
    required String workspaceId,
    required String membershipId,
  });
  Future<Employee> setEmployeeStatus({
    required String workspaceId,
    required String membershipId,
    required EmployeeStatusFilter status,
  });
  Future<Employee> updateCompensation({
    required String workspaceId,
    required String membershipId,
    double? monthlySalary,
    double? hourlyRate,
    int? payrollWorkDays,
  }) => getWorkspaceEmployee(
    workspaceId: workspaceId,
    membershipId: membershipId,
  );
  List<Shift> get availableShifts;
  List<WorkLocation> get availableLocations;
}
