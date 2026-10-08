abstract final class AppRoutes {
  static const dashboard = '/dashboard';
  static const managerShifts = '/dashboard/shifts';
  static const managerPerformance = '/dashboard/performance';
  static String employeePerformance(String membershipId) =>
      '/dashboard/performance/employees/$membershipId';
  static const employees = '/employees';
  static const addEmployee = '/employees/add';
  static String employeeDetails(String id) => '/employees/$id';
  static const attendance = '/attendance';
  static const chat = '/chat';
  static String chatGroup(String id) => '/chat/$id';
  static const attendanceLeaveRequests = '/attendance?tab=leaveRequests';
  static const profile = '/profile';
}
