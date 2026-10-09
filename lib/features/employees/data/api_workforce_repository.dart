import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/models/shift.dart';
import 'package:shiftly/core/models/work_location.dart';
import 'package:shiftly/core/network/api_endpoints.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_repository.dart';

class ApiWorkforceRepository
    implements EmployeeRepository, InvitationRepository, WorkspaceRepository {
  ApiWorkforceRepository(this._dio);

  final Dio _dio;

  @override
  Future<WorkspaceRecord> createWorkspace({
    required String name,
    String? timezone,
  }) => _request(() async {
    final normalizedTimezone = timezone?.trim();
    final response = await _dio.post<Object?>(
      ApiEndpoints.workspaces,
      data: <String, Object?>{
        'name': name.trim(),
        if (normalizedTimezone?.isNotEmpty == true)
          'timezone': normalizedTimezone,
      },
    );
    return _workspace(_map(response.data));
  });

  @override
  Future<List<WorkspaceRecord>> listWorkspaces() => _request(() async {
    final response = await _dio.get<Object?>(ApiEndpoints.workspaces);
    return _list(response.data)
        .map((item) => _workspace(_map(item)))
        .toList(growable: false);
  });

  @override
  Future<WorkspaceRecord> getWorkspace(String workspaceId) => _request(
    () async => _workspace(
      _map((await _dio.get<Object?>(ApiEndpoints.workspace(workspaceId))).data),
    ),
  );

  @override
  Future<EmployeePage> listEmployees({
    required String workspaceId,
    String search = '',
    EmployeeStatusFilter? status,
    int page = 1,
    int limit = 20,
  }) => _request(() async {
    final normalizedSearch = search.trim();
    final response = await _dio.get<Object?>(
      ApiEndpoints.employees(workspaceId),
      queryParameters: <String, Object?>{
        'page': page,
        'limit': limit,
        if (normalizedSearch.isNotEmpty) 'search': normalizedSearch,
        if (status != null) 'status': _employeeStatus(status),
      },
    );
    final body = _map(response.data);
    final pagination = _map(body['pagination']);
    return EmployeePage(
      data: _list(body['data'])
          .map((item) => _employee(_map(item)))
          .toList(growable: false),
      page: _int(pagination, 'page'),
      limit: _int(pagination, 'limit'),
      total: _int(pagination, 'total'),
      totalPages: _int(pagination, 'totalPages'),
    );
  });

  @override
  Future<Employee> getWorkspaceEmployee({
    required String workspaceId,
    required String membershipId,
  }) => _request(
    () async => _employee(
      _map(
        (await _dio.get<Object?>(
          ApiEndpoints.employee(workspaceId, membershipId),
        )).data,
      ),
    ),
  );

  @override
  Future<Employee> setEmployeeStatus({
    required String workspaceId,
    required String membershipId,
    required EmployeeStatusFilter status,
  }) => _request(
    () async => _employee(
      _map(
        (await _dio.patch<Object?>(
          ApiEndpoints.employee(workspaceId, membershipId),
          data: <String, Object?>{'status': _employeeStatus(status)},
        )).data,
      ),
    ),
  );

  @override
  Future<WorkspaceInvitation> createInvitation({
    required String workspaceId,
    required String email,
    String? jobTitle,
  }) => _request(() async {
    final normalizedTitle = jobTitle?.trim();
    final response = await _dio.post<Object?>(
      ApiEndpoints.workspaceInvitations(workspaceId),
      data: <String, Object?>{
        'email': email.trim().toLowerCase(),
        if (normalizedTitle?.isNotEmpty == true) 'jobTitle': normalizedTitle,
      },
    );
    return _managerInvitation(_map(response.data));
  });

  @override
  Future<List<WorkspaceInvitation>> listWorkspaceInvitations({
    required String workspaceId,
    InvitationStatus? status,
  }) => _request(() async {
    final response = await _dio.get<Object?>(
      ApiEndpoints.workspaceInvitations(workspaceId),
      queryParameters: <String, Object?>{
        if (status != null && status != InvitationStatus.unknown)
          'status': _invitationStatus(status),
      },
    );
    return _list(response.data)
        .map((item) => _managerInvitation(_map(item)))
        .toList(growable: false);
  });

  @override
  Future<List<WorkspaceInvitation>> listMyInvitations() => _request(() async {
    final response = await _dio.get<Object?>(ApiEndpoints.myInvitations);
    return _list(response.data)
        .map((item) => _myInvitation(_map(item)))
        .toList(growable: false);
  });

  @override
  Future<WorkspaceRecord> acceptInvitation(String inviteToken) =>
      _request(() async {
        final response = await _dio.post<Object?>(
          ApiEndpoints.acceptInvitation,
          data: <String, Object?>{'inviteToken': inviteToken.trim()},
        );
        final body = _map(response.data);
        final membership = _map(body['membership']);
        return _workspace(<String, Object?>{
          ..._map(body['workspace']),
          'role': membership['role'],
          'status': membership['status'],
        });
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

  Future<T> _request<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error) {
      throw ApiErrorParser.parse(error);
    }
  }
}

WorkspaceRecord _workspace(Map<String, Object?> json) => WorkspaceRecord(
  id: _string(json, 'id'),
  name: _string(json, 'name'),
  code: _string(json, 'code'),
  timezone: _string(json, 'timezone'),
  role: switch (json['role']) {
    'MANAGER' => WorkspaceAccessRole.manager,
    'EMPLOYEE' => WorkspaceAccessRole.employee,
    _ => WorkspaceAccessRole.unknown,
  },
  status: switch (json['status']) {
    'ACTIVE' => WorkspaceAccessStatus.active,
    'INVITED' => WorkspaceAccessStatus.invited,
    'SUSPENDED' => WorkspaceAccessStatus.suspended,
    _ => WorkspaceAccessStatus.unknown,
  },
);

Employee _employee(Map<String, Object?> json) => Employee(
  id: _string(json, 'id'),
  profileId: _string(json, 'profileId'),
  fullName: _optionalString(json['fullName']),
  phone: _optionalString(json['phone']),
  email: _optionalString(json['email']),
  jobTitle: _optionalString(json['jobTitle']),
  location: null,
  shift: null,
  startDate: _optionalDate(json['joinedAt']),
  employmentStatus: switch (json['status']) {
    'ACTIVE' => EmploymentStatus.active,
    'SUSPENDED' => EmploymentStatus.suspended,
    _ => EmploymentStatus.unknown,
  },
  role: switch (json['role']) {
    'EMPLOYEE' => EmployeeRole.employee,
    'MANAGER' => EmployeeRole.manager,
    _ => EmployeeRole.unknown,
  },
  avatarUrl: _optionalString(json['avatarUrl']),
  createdAt: _requiredDate(json, 'createdAt'),
  updatedAt: _requiredDate(json, 'updatedAt'),
);

WorkspaceInvitation _managerInvitation(Map<String, Object?> json) =>
    WorkspaceInvitation(
      id: _string(json, 'id'),
      workspaceId: _string(json, 'workspaceId'),
      email: _optionalString(json['email']),
      jobTitle: _optionalString(json['jobTitle']),
      role: _role(json['role']),
      status: _invitation(json['status']),
      expiresAt: _requiredDate(json, 'expiresAt'),
      acceptedAt: _optionalDate(json['acceptedAt']),
      revokedAt: _optionalDate(json['revokedAt']),
      createdAt: _requiredDate(json, 'createdAt'),
      updatedAt: _requiredDate(json, 'updatedAt'),
      inviteToken: _optionalString(json['inviteToken']),
    );

WorkspaceInvitation _myInvitation(Map<String, Object?> json) {
  final workspaceJson = _map(json['workspace']);
  final workspace = WorkspaceRecord(
    id: _string(workspaceJson, 'id'),
    name: _string(workspaceJson, 'name'),
    code: _string(workspaceJson, 'code'),
    timezone: _string(workspaceJson, 'timezone'),
    role: WorkspaceAccessRole.employee,
    status: WorkspaceAccessStatus.invited,
  );
  return WorkspaceInvitation(
    id: _string(json, 'id'),
    workspaceId: workspace.id,
    jobTitle: _optionalString(json['jobTitle']),
    role: _role(json['role']),
    status: InvitationStatus.pending,
    expiresAt: _requiredDate(json, 'expiresAt'),
    workspace: workspace,
  );
}

String _employeeStatus(EmployeeStatusFilter status) => switch (status) {
  EmployeeStatusFilter.active => 'ACTIVE',
  EmployeeStatusFilter.suspended => 'SUSPENDED',
};

String _invitationStatus(InvitationStatus status) => switch (status) {
  InvitationStatus.pending => 'PENDING',
  InvitationStatus.accepted => 'ACCEPTED',
  InvitationStatus.revoked => 'REVOKED',
  InvitationStatus.expired => 'EXPIRED',
  InvitationStatus.unknown => throw ArgumentError('Unknown invitation status'),
};

InvitationStatus _invitation(Object? value) => switch (value) {
  'PENDING' => InvitationStatus.pending,
  'ACCEPTED' => InvitationStatus.accepted,
  'REVOKED' => InvitationStatus.revoked,
  'EXPIRED' => InvitationStatus.expired,
  _ => InvitationStatus.unknown,
};

WorkspaceAccessRole _role(Object? value) => switch (value) {
  'MANAGER' => WorkspaceAccessRole.manager,
  'EMPLOYEE' => WorkspaceAccessRole.employee,
  _ => WorkspaceAccessRole.unknown,
};

Map<String, Object?> _map(Object? value) {
  if (value is! Map) throw const FormatException('Invalid response object');
  return Map<String, Object?>.from(value);
}

List<Object?> _list(Object? value) {
  if (value is! List) throw const FormatException('Invalid response list');
  return value;
}

String _string(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) throw FormatException('Invalid $key');
  return value;
}

int _int(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int || value < 0) throw FormatException('Invalid $key');
  return value;
}

String? _optionalString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

DateTime _requiredDate(Map<String, Object?> json, String key) {
  final value = _optionalDate(json[key]);
  if (value == null) throw FormatException('Invalid $key');
  return value;
}

DateTime? _optionalDate(Object? value) {
  if (value == null) return null;
  final parsed = value is String ? DateTime.tryParse(value) : null;
  if (parsed == null) throw const FormatException('Invalid date');
  return parsed.toUtc();
}
