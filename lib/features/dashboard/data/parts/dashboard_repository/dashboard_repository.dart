part of '../../dashboard_repository.dart';

abstract interface class DashboardRepository {
  Future<ManagerDashboardData> getManagerDashboard(String workspaceId);
  Future<EmployeeDashboardData> getEmployeeDashboard(String workspaceId);
}
