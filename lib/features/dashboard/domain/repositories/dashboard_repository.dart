import 'package:shiftly/features/dashboard/domain/entities/dashboard_models.dart';

export 'package:shiftly/features/dashboard/domain/entities/dashboard_models.dart';

abstract interface class DashboardRepository {
  Future<ManagerDashboardData> getManagerDashboard(String workspaceId);
  Future<EmployeeDashboardData> getEmployeeDashboard(String workspaceId);
}
