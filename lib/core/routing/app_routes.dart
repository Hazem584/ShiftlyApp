abstract final class AppRoutes {
  static const dashboard = '/dashboard';
  static const employees = '/employees';
  static const addEmployee = '/employees/add';
  static String employeeDetails(String id) => '/employees/$id';
  static const attendance = '/attendance';
  static const attendanceLeaveRequests = '/attendance?tab=leaveRequests';
  static const profile = '/profile';
}
