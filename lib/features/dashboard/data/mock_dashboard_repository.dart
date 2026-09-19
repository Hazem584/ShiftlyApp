import 'package:shiftly/core/models/attendance_record.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/features/dashboard/data/dashboard_repository.dart';
import 'package:shiftly/features/employees/data/employee_repository.dart';

class MockDashboardRepository implements DashboardRepository {
  MockDashboardRepository({
    required this.employeeRepository,
    this.delay = const Duration(milliseconds: 550),
    this.shouldFail = false,
  });

  final EmployeeRepository employeeRepository;
  final Duration delay;
  final bool shouldFail;

  @override
  Future<DashboardData> getDashboard() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (shouldFail) throw Exception('Unable to load dashboard');
    final employees = await employeeRepository.getEmployees();
    final now = DateTime.now();
    final currentShift = employeeRepository.availableShifts.first;
    if (employees.isEmpty) {
      return DashboardData(
        totalEmployees: 0,
        presentEmployees: 0,
        absentEmployees: 0,
        lateEmployees: 0,
        pendingRequests: 0,
        recentActivity: const [],
        currentShift: currentShift,
        currentShiftEmployees: 0,
      );
    }
    final attended = employees
        .where(
          (employee) => employee.attendanceStatus != AttendanceStatus.absent,
        )
        .take(3)
        .toList();
    return DashboardData(
      totalEmployees: employees.length,
      presentEmployees: employees
          .where(
            (employee) => employee.attendanceStatus == AttendanceStatus.present,
          )
          .length,
      absentEmployees: employees
          .where(
            (employee) => employee.attendanceStatus == AttendanceStatus.absent,
          )
          .length,
      lateEmployees: employees
          .where(
            (employee) => employee.attendanceStatus == AttendanceStatus.late,
          )
          .length,
      pendingRequests: 3,
      currentShift: currentShift,
      currentShiftEmployees: 3,
      recentActivity: List.generate(attended.length, (index) {
        final employee = attended[index];
        return AttendanceRecord(
          id: 'record-${index + 1}',
          employeeId: employee.id,
          employeeName: employee.fullName,
          occurredAt: DateTime(
            now.year,
            now.month,
            now.day,
            7,
            56 + (index * 9),
          ),
          isCheckIn: true,
          isLate: employee.attendanceStatus == AttendanceStatus.late,
        );
      }),
    );
  }
}
