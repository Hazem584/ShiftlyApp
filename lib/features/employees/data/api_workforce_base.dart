import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/network/api_endpoints.dart';
import 'package:shiftly/features/employees/data/workforce_entity_mapper.dart';
import 'package:shiftly/features/employees/data/workforce_json_parser.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_exit_repository.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_repository.dart';

abstract class ApiWorkforceBase
    implements WorkspaceRepository, WorkspaceExitRepository {
  ApiWorkforceBase(this.dio);

  final Dio dio;

  Future<T> request<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error) {
      throw ApiErrorParser.parse(error);
    }
  }

  @override
  Future<void> leaveWorkspace(String workspaceId, {String? confirmation}) =>
      request(() async {
        await dio.post<Object?>(
          '/workspaces/$workspaceId/leave',
          data: {'confirmation': ?confirmation},
        );
      });

  @override
  Future<WorkspaceRecord> createWorkspace({
    required String name,
    String? timezone,
  }) => request(() async {
    final normalizedTimezone = timezone?.trim();
    final response = await dio.post<Object?>(
      ApiEndpoints.workspaces,
      data: <String, Object?>{
        'name': name.trim(),
        if (normalizedTimezone?.isNotEmpty == true)
          'timezone': normalizedTimezone,
      },
    );
    return parseWorkspaceRecord(asJsonMap(response.data));
  });

  @override
  Future<List<WorkspaceRecord>> listWorkspaces() => request(() async {
    final response = await dio.get<Object?>(ApiEndpoints.workspaces);
    return asJsonList(response.data)
        .map((item) => parseWorkspaceRecord(asJsonMap(item)))
        .toList(growable: false);
  });

  @override
  Future<WorkspaceRecord> getWorkspace(String workspaceId) => request(
    () async => parseWorkspaceRecord(
      asJsonMap(
        (await dio.get<Object?>(ApiEndpoints.workspace(workspaceId))).data,
      ),
    ),
  );
}
