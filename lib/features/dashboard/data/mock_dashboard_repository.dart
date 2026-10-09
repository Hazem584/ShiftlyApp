import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';

class MockDashboardRepository implements DashboardRepository {
  MockDashboardRepository({
    required this.employeeRepository,
    this.delay = const Duration(milliseconds: 550),
    this.shouldFail = false,
    this.timezone = 'Etc/UTC',
    this.employeeMembershipId = '040e52de-05b9-46b8-80ca-e7df3ef7444b',
  });

  final EmployeeRepository employeeRepository;
  final Duration delay;
  final bool shouldFail;
  final String timezone;
  final String employeeMembershipId;

  Future<void> _prepare() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (shouldFail) throw Exception('Unable to load dashboard');
  }

  @override
  Future<ManagerDashboardData> getManagerDashboard(String workspaceId) async {
    await _prepare();
    final employees = await employeeRepository.getEmployees();
    final now = DateTime.now().toUtc();
    return ManagerDashboardData(
      date: _date(now),
      timezone: timezone,
      generatedAt: now,
      summary: ManagerDashboardSummary(
        totalEmployees: employees.length,
        scheduledToday: 0,
        clockedInNow: 0,
        completedToday: 0,
        lateToday: 0,
        missedToday: 0,
        onApprovedLeave: 0,
        pendingLeaveRequests: 0,
        unreadNotifications: 0,
      ),
      todayShifts: const [],
      pendingLeaveRequests: const [],
    );
  }

  @override
  Future<EmployeeDashboardData> getEmployeeDashboard(String workspaceId) async {
    await _prepare();
    final now = DateTime.now().toUtc();
    return EmployeeDashboardData(
      date: _date(now),
      timezone: timezone,
      generatedAt: now,
      employee: EmployeeDashboardIdentity(
        membershipId: employeeMembershipId,
        fullName: 'Preview employee',
      ),
      summary: const EmployeeDashboardSummary(
        pendingLeaveRequests: 0,
        approvedLeaveRequests: 0,
        unreadNotifications: 0,
      ),
      recentLeaveRequests: const [],
    );
  }
}

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
