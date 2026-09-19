import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/models/shift.dart';
import 'package:shiftly/core/models/work_location.dart';

abstract interface class EmployeeRepository {
  Future<List<Employee>> getEmployees({String query = ''});
  Future<Employee?> getEmployee(String id);
  Future<void> addEmployee(Employee employee);
  List<Shift> get availableShifts;
  List<WorkLocation> get availableLocations;
}
