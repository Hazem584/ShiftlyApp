import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';

class ApiDashboardRepository implements DashboardRepository {
  ApiDashboardRepository(this._dio);
  final Dio _dio;

  @override
  Future<ManagerDashboardData> getManagerDashboard(String workspaceId) =>
      _request(() async {
        final response = await _dio.get<Object?>(
          '/workspaces/$workspaceId/dashboard',
        );
        return ManagerDashboardData.fromJson(
          ApiModelParser.map(response.data, 'managerDashboard'),
        );
      });

  @override
  Future<EmployeeDashboardData> getEmployeeDashboard(String workspaceId) =>
      _request(() async {
        final response = await _dio.get<Object?>(
          '/dashboard/me',
          queryParameters: {'workspaceId': workspaceId},
        );
        return EmployeeDashboardData.fromJson(
          ApiModelParser.map(response.data, 'employeeDashboard'),
        );
      });

  Future<T> _request<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error) {
      throw ApiErrorParser.parse(error);
    }
  }
}
