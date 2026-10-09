import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/features/employees/data/api_workforce_repository.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_repository.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);
  final FutureOr<ResponseBody> Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object value, {int status = 200}) => ResponseBody.fromString(
  jsonEncode(value),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

Map<String, Object?> _workspace({
  String role = 'MANAGER',
  String status = 'ACTIVE',
}) => {
  'id': 'workspace-id',
  'name': 'Cairo Operations',
  'code': 'CAIRO',
  'timezone': 'Africa/Cairo',
  'role': role,
  'status': status,
};

Map<String, Object?> _employee({String status = 'ACTIVE'}) => {
  'id': 'membership-id',
  'profileId': 'profile-id',
  'fullName': 'Employee Name',
  'email': 'employee@example.test',
  'phone': null,
  'avatarUrl': null,
  'jobTitle': 'Cashier',
  'role': 'EMPLOYEE',
  'status': status,
  'joinedAt': '2026-09-01T00:00:00.000Z',
  'createdAt': '2026-08-01T00:00:00.000Z',
  'updatedAt': '2026-09-01T00:00:00.000Z',
};

Map<String, Object?> _invitation({bool token = false}) => {
  'id': 'invitation-id',
  'workspaceId': 'workspace-id',
  'email': 'employee@example.test',
  'role': 'EMPLOYEE',
  'status': 'PENDING',
  'jobTitle': 'Cashier',
  'expiresAt': '2026-10-01T00:00:00.000Z',
  'acceptedAt': null,
  'revokedAt': null,
  'createdAt': '2026-09-01T00:00:00.000Z',
  'updatedAt': '2026-09-01T00:00:00.000Z',
  if (token) 'inviteToken': 'sensitive-token',
};

({ApiWorkforceRepository repository, _Adapter adapter}) _repository(
  FutureOr<ResponseBody> Function(RequestOptions options) handler,
) {
  final adapter = _Adapter(handler);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com/api/v1'))
    ..httpClientAdapter = adapter;
  return (repository: ApiWorkforceRepository(dio), adapter: adapter);
}

void main() {
  test(
    'workspace create/list/details use confirmed routes and payload',
    () async {
      final client = _repository(
        (options) => switch ((options.method, options.uri.path)) {
          ('POST', '/api/v1/workspaces') => _json(_workspace()),
          ('GET', '/api/v1/workspaces') => _json([_workspace()]),
          _ => _json(_workspace()),
        },
      );
      await client.repository.createWorkspace(
        name: ' Cairo Operations ',
        timezone: ' Africa/Cairo ',
      );
      await client.repository.listWorkspaces();
      final detail = await client.repository.getWorkspace('workspace-id');
      expect(client.adapter.requests.first.data, {
        'name': 'Cairo Operations',
        'timezone': 'Africa/Cairo',
      });
      expect(client.adapter.requests.map((item) => item.uri.path), [
        '/api/v1/workspaces',
        '/api/v1/workspaces',
        '/api/v1/workspaces/workspace-id',
      ]);
      expect(detail.grantsAccess, isTrue);
    },
  );

  test('employee list scopes filters and parses pagination', () async {
    final client = _repository(
      (_) => _json({
        'data': [_employee()],
        'pagination': {'page': 2, 'limit': 20, 'total': 21, 'totalPages': 2},
      }),
    );
    final page = await client.repository.listEmployees(
      workspaceId: 'workspace-id',
      search: ' Employee ',
      status: EmployeeStatusFilter.active,
      page: 2,
    );
    final request = client.adapter.requests.single;
    expect(request.uri.path, '/api/v1/workspaces/workspace-id/employees');
    expect(request.queryParameters, {
      'page': 2,
      'limit': 20,
      'search': 'Employee',
      'status': 'ACTIVE',
    });
    expect(page.totalPages, 2);
    expect(page.data.single.id, 'membership-id');
    expect(page.data.single.profileId, 'profile-id');
    expect(page.data.single.phone, isNull);
  });

  test('details and status updates use membership id only', () async {
    final client = _repository((_) => _json(_employee(status: 'SUSPENDED')));
    await client.repository.getWorkspaceEmployee(
      workspaceId: 'workspace-id',
      membershipId: 'membership-id',
    );
    final updated = await client.repository.setEmployeeStatus(
      workspaceId: 'workspace-id',
      membershipId: 'membership-id',
      status: EmployeeStatusFilter.suspended,
    );
    expect(
      client.adapter.requests.first.uri.path,
      '/api/v1/workspaces/workspace-id/employees/membership-id',
    );
    expect(client.adapter.requests.last.data, {'status': 'SUSPENDED'});
    expect(updated.employmentStatus, EmploymentStatus.suspended);
  });

  test('invitation create sends only email and optional job title', () async {
    final client = _repository(
      (_) => _json(_invitation(token: true), status: 201),
    );
    final invitation = await client.repository.createInvitation(
      workspaceId: 'workspace-id',
      email: ' EMPLOYEE@EXAMPLE.TEST ',
      jobTitle: ' Cashier ',
    );
    expect(client.adapter.requests.single.data, {
      'email': 'employee@example.test',
      'jobTitle': 'Cashier',
    });
    expect(
      (client.adapter.requests.single.data as Map).keys,
      unorderedEquals(['email', 'jobTitle']),
    );
    expect(invitation.inviteToken, 'sensitive-token');
  });

  test('manager and employee invitation listing use separate routes', () async {
    final client = _repository(
      (options) => options.uri.path.endsWith('/invitations/me')
          ? _json([
              {
                'id': 'invitation-id',
                'role': 'EMPLOYEE',
                'jobTitle': null,
                'expiresAt': '2026-10-01T00:00:00.000Z',
                'workspace': _workspace(role: 'EMPLOYEE', status: 'INVITED'),
              },
            ])
          : _json([_invitation()]),
    );
    final pending = await client.repository.listWorkspaceInvitations(
      workspaceId: 'workspace-id',
      status: InvitationStatus.pending,
    );
    final mine = await client.repository.listMyInvitations();
    expect(client.adapter.requests.first.queryParameters, {
      'status': 'PENDING',
    });
    expect(pending.single.status, InvitationStatus.pending);
    expect(mine.single.workspace?.status, WorkspaceAccessStatus.invited);
  });

  test('accept invitation parses canonical workspace membership', () async {
    final client = _repository(
      (_) => _json({
        'workspace': {
          'id': 'workspace-id',
          'name': 'Cairo Operations',
          'code': 'CAIRO',
          'timezone': 'Africa/Cairo',
        },
        'membership': {'role': 'EMPLOYEE', 'status': 'ACTIVE'},
      }, status: 201),
    );
    final workspace = await client.repository.acceptInvitation(' token-value ');
    expect(client.adapter.requests.single.data, {'inviteToken': 'token-value'});
    expect(workspace.role, WorkspaceAccessRole.employee);
    expect(workspace.grantsAccess, isTrue);
  });

  test('unknown role and status never grant access', () async {
    final client = _repository(
      (_) => _json(_workspace(role: 'OWNER', status: 'ENABLED')),
    );
    final workspace = await client.repository.getWorkspace('workspace-id');
    expect(workspace.role, WorkspaceAccessRole.unknown);
    expect(workspace.status, WorkspaceAccessStatus.unknown);
    expect(workspace.grantsAccess, isFalse);
  });

  test('malformed success and backend request id become safe typed errors', () async {
    final malformed = _repository((_) => _json({'id': 'only-id'}));
    await expectLater(
      malformed.repository.getWorkspace('workspace-id'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'We could not read the latest information. Refresh to load it again.',
        ),
      ),
    );
    final backend = _repository(
      (_) => _json({
        'statusCode': 409,
        'code': 'INVITATION_ALREADY_PENDING',
        'message': 'private backend detail',
        'requestId': 'request-id',
      }, status: 409),
    );
    await expectLater(
      backend.repository.createInvitation(
        workspaceId: 'workspace-id',
        email: 'a@example.test',
      ),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'INVITATION_ALREADY_PENDING')
            .having((error) => error.requestId, 'requestId', 'request-id'),
      ),
    );
  });
}
