part of '../../employee_repository.dart';

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
  List<Shift> get availableShifts;
  List<WorkLocation> get availableLocations;
}
