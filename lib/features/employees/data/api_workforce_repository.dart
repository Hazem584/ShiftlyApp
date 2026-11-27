import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/models/shift.dart';
import 'package:shiftly/core/models/work_location.dart';
import 'package:shiftly/core/network/api_endpoints.dart';
import 'package:shiftly/features/employees/data/api_invitation_mixin.dart';
import 'package:shiftly/features/employees/data/api_workforce_base.dart';
import 'package:shiftly/features/employees/data/workforce_entity_mapper.dart';
import 'package:shiftly/features/employees/data/workforce_json_parser.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';

class ApiWorkforceRepository extends ApiWorkforceBase
    with ApiInvitationMixin
    implements EmployeeRepository {
  ApiWorkforceRepository(super.dio);

  @override
  Future<EmployeePage> listEmployees({
    required String workspaceId,
    String search = '',
    EmployeeStatusFilter? status,
    int page = 1,
    int limit = 20,
  }) => request(() async {
    final q = search.trim();
    final res = await dio.get<Object?>(
      ApiEndpoints.employees(workspaceId),
      queryParameters: <String, Object?>{
        'page': page,
        'limit': limit,
        if (q.isNotEmpty) 'search': q,
        if (status != null) 'status': employeeStatusValue(status),
      },
    );
    final body = asJsonMap(res.data), pg = asJsonMap(body['pagination']);
    return EmployeePage(
      data: asJsonList(body['data'])
          .map((item) => parseEmployee(asJsonMap(item)))
          .toList(growable: false),
      page: readInt(pg, 'page'),
      limit: readInt(pg, 'limit'),
      total: readInt(pg, 'total'),
      totalPages: readInt(pg, 'totalPages'),
    );
  });

  @override
  Future<Employee> getWorkspaceEmployee({
    required String workspaceId,
    required String membershipId,
  }) => request(() async {
    final url = ApiEndpoints.employee(workspaceId, membershipId);
    return parseEmployee(asJsonMap((await dio.get<Object?>(url)).data));
  });

  @override
  Future<Employee> setEmployeeStatus({
    required String workspaceId,
    required String membershipId,
    required EmployeeStatusFilter status,
  }) => request(() async {
    final url = ApiEndpoints.employee(workspaceId, membershipId);
    final data = <String, Object?>{'status': employeeStatusValue(status)};
    return parseEmployee(
      asJsonMap((await dio.patch<Object?>(url, data: data)).data),
    );
  });

  @override
  Future<List<Employee>> getEmployees({String query = ''}) async =>
      throw UnsupportedError('A workspace scope is required');

  @override
  Future<Employee?> getEmployee(String id) async =>
      throw UnsupportedError('A workspace scope is required');

  @override
  Future<void> addEmployee(Employee employee) async =>
      throw UnsupportedError('Employees are created through invitations');

  @override
  List<Shift> get availableShifts => const [];

  @override
  List<WorkLocation> get availableLocations => const [];
}
