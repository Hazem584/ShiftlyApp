import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/models/shift.dart';
import 'package:shiftly/core/models/work_location.dart';
import 'package:shiftly/features/employees/data/employee_repository.dart';

class MockEmployeeRepository implements EmployeeRepository {
  MockEmployeeRepository({
    this.delay = const Duration(milliseconds: 350),
    this.shouldFail = false,
    List<Employee>? initialEmployees,
  }) : _employees = List.of(initialEmployees ?? _seedEmployees());

  final Duration delay;
  final bool shouldFail;
  final List<Employee> _employees;

  static final _locations = [
    const WorkLocation(
      id: 'main',
      name: 'Shift Lab – Main Branch',
      address: 'Cairo',
    ),
    const WorkLocation(
      id: 'west',
      name: 'Shift Lab – West Branch',
      address: 'Giza',
    ),
  ];

  static final _shifts = [
    Shift(
      id: 'morning',
      name: 'Morning Shift',
      startTime: DateTime(2026, 1, 1, 8),
      endTime: DateTime(2026, 1, 1, 16),
    ),
    Shift(
      id: 'evening',
      name: 'Evening Shift',
      startTime: DateTime(2026, 1, 1, 16),
      endTime: DateTime(2026, 1, 2),
    ),
  ];

  static List<Employee> _seedEmployees() => [
    Employee(
      id: 'emp-1',
      fullName: 'Mariam Hassan',
      phone: '+20 100 123 4567',
      email: 'mariam@shiftlab.com',
      jobTitle: 'Operations Lead',
      location: _locations[0],
      shift: _shifts[0],
      startDate: DateTime(2024, 2, 12),
      employmentStatus: EmploymentStatus.active,
      attendanceStatus: AttendanceStatus.present,
    ),
    Employee(
      id: 'emp-2',
      fullName: 'Omar Khaled',
      phone: '+20 111 234 5678',
      email: 'omar@shiftlab.com',
      jobTitle: 'Lab Technician',
      location: _locations[0],
      shift: _shifts[0],
      startDate: DateTime(2024, 6, 3),
      employmentStatus: EmploymentStatus.active,
      attendanceStatus: AttendanceStatus.late,
    ),
    Employee(
      id: 'emp-3',
      fullName: 'Nour Adel',
      phone: '+20 122 345 6789',
      email: 'nour@shiftlab.com',
      jobTitle: 'Customer Specialist',
      location: _locations[1],
      shift: _shifts[1],
      startDate: DateTime(2025, 1, 20),
      employmentStatus: EmploymentStatus.onLeave,
      attendanceStatus: AttendanceStatus.absent,
    ),
    Employee(
      id: 'emp-4',
      fullName: 'Youssef Samir',
      phone: '+20 155 456 7890',
      email: 'youssef@shiftlab.com',
      jobTitle: 'Lab Technician',
      location: _locations[0],
      shift: _shifts[0],
      startDate: DateTime(2025, 4, 7),
      employmentStatus: EmploymentStatus.active,
      attendanceStatus: AttendanceStatus.present,
    ),
  ];

  @override
  List<Shift> get availableShifts => List.unmodifiable(_shifts);

  @override
  List<WorkLocation> get availableLocations => List.unmodifiable(_locations);

  @override
  Future<List<Employee>> getEmployees({String query = ''}) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (shouldFail) throw Exception('Unable to load employees');
    final normalized = query.trim().toLowerCase();
    return List.unmodifiable(
      _employees.where(
        (employee) =>
            normalized.isEmpty ||
            employee.fullName.toLowerCase().contains(normalized),
      ),
    );
  }

  @override
  Future<Employee?> getEmployee(String id) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (shouldFail) throw Exception('Unable to load employee');
    return _employees.cast<Employee?>().firstWhere(
      (employee) => employee?.id == id,
      orElse: () => null,
    );
  }

  @override
  Future<void> addEmployee(Employee employee) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (shouldFail) throw Exception('Unable to add employee');
    _employees.add(employee);
  }
}
