import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/models/shift.dart';
import 'package:shiftly/core/models/work_location.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/employees/data/employee_repository.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit.dart';
import 'package:shiftly/features/invitations/data/invitation_repository.dart';
import 'package:shiftly/features/workspaces/data/workspace_repository.dart';

Employee _employee(
  String id, {
  EmploymentStatus status = EmploymentStatus.active,
}) => Employee(
  id: id,
  profileId: 'profile-$id',
  fullName: 'Employee $id',
  phone: null,
  email: '$id@example.test',
  jobTitle: null,
  location: null,
  shift: null,
  startDate: DateTime.utc(2026),
  employmentStatus: status,
);

class _Repository implements EmployeeRepository, InvitationRepository {
  final pages = <int, EmployeePage>{};
  final pending = <WorkspaceInvitation>[];
  Completer<EmployeePage>? pendingLoad;
  Object? listError;
  int listCalls = 0;
  int invitationCalls = 0;
  int updateCalls = 0;

  @override
  Future<EmployeePage> listEmployees({
    required String workspaceId,
    String search = '',
    EmployeeStatusFilter? status,
    int page = 1,
    int limit = 20,
  }) async {
    listCalls++;
    if (listError case final Object error) throw error;
    if (pendingLoad case final value?) return value.future;
    if (search.trim().isNotEmpty) {
      return EmployeePage(
        data: const [],
        page: page,
        limit: limit,
        total: 0,
        totalPages: 0,
      );
    }
    return pages[page] ??
        EmployeePage(
          data: const [],
          page: page,
          limit: limit,
          total: 0,
          totalPages: 0,
        );
  }

  @override
  Future<List<WorkspaceInvitation>> listWorkspaceInvitations({
    required String workspaceId,
    InvitationStatus? status,
  }) async {
    invitationCalls++;
    return List.unmodifiable(pending);
  }

  @override
  Future<WorkspaceInvitation> createInvitation({
    required String workspaceId,
    required String email,
    String? jobTitle,
  }) async {
    final value = WorkspaceInvitation(
      id: 'invite-${pending.length}',
      workspaceId: workspaceId,
      email: email,
      jobTitle: jobTitle,
      status: InvitationStatus.pending,
      inviteToken: 'one-time-token',
    );
    pending.add(value);
    return value;
  }

  @override
  Future<Employee> setEmployeeStatus({
    required String workspaceId,
    required String membershipId,
    required EmployeeStatusFilter status,
  }) async {
    updateCalls++;
    return _employee(
      membershipId,
      status: status == EmployeeStatusFilter.active
          ? EmploymentStatus.active
          : EmploymentStatus.suspended,
    );
  }

  @override
  Future<Employee> getWorkspaceEmployee({
    required String workspaceId,
    required String membershipId,
  }) async => _employee(membershipId);
  @override
  Future<List<Employee>> getEmployees({String query = ''}) async => const [];
  @override
  Future<Employee?> getEmployee(String id) async => null;
  @override
  Future<void> addEmployee(Employee employee) async {}
  @override
  List<Shift> get availableShifts => const [];
  @override
  List<WorkLocation> get availableLocations => const [];
  @override
  Future<List<WorkspaceInvitation>> listMyInvitations() async => const [];
  @override
  Future<WorkspaceRecord> acceptInvitation(String inviteToken) =>
      throw UnimplementedError();
}

const _scopeA = EmployeeSessionScope(
  userId: 'user-a',
  workspaceId: 'workspace-a',
  role: WorkspaceRole.manager,
);
const _scopeB = EmployeeSessionScope(
  userId: 'user-b',
  workspaceId: 'workspace-b',
  role: WorkspaceRole.manager,
);

void main() {
  test(
    'initial, empty, search, status, pagination and duplicate prevention',
    () async {
      final repository = _Repository()
        ..pages[1] = EmployeePage(
          data: [_employee('one')],
          page: 1,
          limit: 20,
          total: 2,
          totalPages: 2,
        )
        ..pages[2] = EmployeePage(
          data: [_employee('two')],
          page: 2,
          limit: 20,
          total: 2,
          totalPages: 2,
        );
      final cubit = EmployeesCubit(repository, invitations: repository);
      addTearDown(cubit.close);
      cubit.bindSession(_scopeA);
      await Future<void>.delayed(Duration.zero);
      expect((cubit.state as EmployeesLoaded).employees.single.id, 'one');
      final firstMore = cubit.loadMore();
      final duplicate = cubit.loadMore();
      await Future.wait([firstMore, duplicate]);
      expect(
        (cubit.state as EmployeesLoaded).employees.map((item) => item.id),
        ['one', 'two'],
      );
      expect(repository.listCalls, 2);
      await cubit.load(
        query: ' nobody ',
        status: EmployeeStatusFilter.suspended,
      );
      expect((cubit.state as EmployeesLoaded).employees, isEmpty);
      expect(
        (cubit.state as EmployeesLoaded).status,
        EmployeeStatusFilter.suspended,
      );
    },
  );

  test('refresh failure retains current employees', () async {
    final repository = _Repository()
      ..pages[1] = EmployeePage(
        data: [_employee('one')],
        page: 1,
        limit: 20,
        total: 1,
        totalPages: 1,
      );
    final cubit = EmployeesCubit(repository, invitations: repository);
    addTearDown(cubit.close);
    cubit.bindSession(_scopeA);
    await Future<void>.delayed(Duration.zero);
    repository.listError = const ApiException(message: 'Safe refresh failure');
    await cubit.load(refresh: true);
    final state = cubit.state as EmployeesLoaded;
    expect(state.employees.single.id, 'one');
    expect(state.failure?.message, 'Safe refresh failure');
  });

  test(
    'logout, user switch, workspace switch and stale load isolate data',
    () async {
      final oldLoad = Completer<EmployeePage>();
      final repository = _Repository()..pendingLoad = oldLoad;
      final cubit = EmployeesCubit(repository, invitations: repository);
      addTearDown(cubit.close);
      cubit.bindSession(_scopeA);
      cubit.bindSession(null);
      expect(cubit.state, isA<EmployeesLoading>());
      repository.pendingLoad = null;
      repository.pages[1] = EmployeePage(
        data: [_employee('user-b')],
        page: 1,
        limit: 20,
        total: 1,
        totalPages: 1,
      );
      cubit.bindSession(_scopeB);
      await Future<void>.delayed(Duration.zero);
      oldLoad.complete(
        EmployeePage(
          data: [_employee('user-a')],
          page: 1,
          limit: 20,
          total: 1,
          totalPages: 1,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect((cubit.state as EmployeesLoaded).employees.single.id, 'user-b');
      cubit.bindSession(
        const EmployeeSessionScope(
          userId: 'user-b',
          workspaceId: 'workspace-c',
          role: WorkspaceRole.manager,
        ),
      );
      expect(cubit.state, isA<EmployeesLoading>());
    },
  );

  test('same-scope refresh does not reload and invite/status use canonical responses', () async {
    final repository = _Repository()
      ..pages[1] = EmployeePage(
        data: [_employee('one')],
        page: 1,
        limit: 20,
        total: 1,
        totalPages: 1,
      );
    var dashboardRefreshes = 0;
    final cubit = EmployeesCubit(
      repository,
      invitations: repository,
      onDashboardChanged: () => dashboardRefreshes += 1,
    );
    addTearDown(cubit.close);
    cubit.bindSession(_scopeA);
    await Future<void>.delayed(Duration.zero);
    cubit.bindSession(_scopeA);
    expect(repository.listCalls, 1);
    final invitation = await cubit.invite(email: 'employee@example.test');
    expect(invitation?.inviteToken, 'one-time-token');
    expect((cubit.state as EmployeesLoaded).pendingInvitations, hasLength(1));
    expect(dashboardRefreshes, 0);
    expect(
      await cubit.setStatus('one', EmployeeStatusFilter.suspended),
      EmployeeOperationResult.success,
    );
    expect(
      (cubit.state as EmployeesLoaded).employees.single.employmentStatus,
      EmploymentStatus.suspended,
    );
    expect(dashboardRefreshes, 1);
  });
}
