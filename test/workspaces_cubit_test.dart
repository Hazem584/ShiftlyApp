import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_repository.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_cubit.dart';

const _workspace = WorkspaceRecord(
  id: 'workspace-1',
  name: 'Shiftly Cairo',
  code: 'CAIRO',
  timezone: 'Africa/Cairo',
  role: WorkspaceAccessRole.manager,
  status: WorkspaceAccessStatus.active,
);

const _invitation = WorkspaceInvitation(
  id: 'invitation-1',
  workspaceId: 'workspace-2',
  status: InvitationStatus.pending,
);

MembershipRefreshResult _authorized(
  String workspaceId, {
  String userId = 'user-1',
  WorkspaceRole role = WorkspaceRole.manager,
}) => MembershipRefreshResult.authorized(
  userId: userId,
  workspaceId: workspaceId,
  role: role,
);

void main() {
  test(
    'accepts the listed invitation by ID and refreshes that workspace',
    () async {
      final invitations = _FakeInvitationRepository();
      String? selected;
      final cubit = WorkspacesCubit(
        _FakeWorkspaceRepository(),
        invitations,
        onMembershipChanged: (workspaceId, userId) async {
          selected = workspaceId;
          return _authorized(
            workspaceId,
            userId: userId,
            role: WorkspaceRole.employee,
          );
        },
      )..bindUser('user-1');
      await _settle();
      expect(await cubit.acceptById(_invitation.id), isTrue);
      expect(invitations.acceptedId, _invitation.id);
      expect(selected, 'workspace-2');
      expect(cubit.state.busy, isFalse);
      await cubit.close();
    },
  );
  test('decline removes the invitation without switching memberships or duplicating requests', () async {
    final gate = Completer<void>();
    final invitations = _FakeInvitationRepository()..declineGate = gate.future;
    var membershipChanges = 0;
    final cubit = WorkspacesCubit(
      _FakeWorkspaceRepository(),
      invitations,
      onMembershipChanged: (_, _) async {
        membershipChanges++;
        return const MembershipRefreshResult.failed();
      },
    )..bindUser('user-1');
    await _settle();
    final request = cubit.decline(_invitation.id);
    expect(cubit.state.respondingInvitationId, _invitation.id);
    expect(await cubit.acceptById(_invitation.id), isFalse);
    expect(await cubit.decline(_invitation.id), isFalse);
    gate.complete();
    expect(await request, isTrue);
    expect(cubit.state.invitations, isEmpty);
    expect(cubit.state.workspaces, [_workspace]);
    expect(membershipChanges, 0);
    expect(cubit.state.busy, isFalse);
    await cubit.close();
  });
  test('failed decline keeps the invitation and can be retried', () async {
    final invitations = _FakeInvitationRepository(
      acceptError: const ApiException(message: 'Offline'),
    );
    final cubit = WorkspacesCubit(
      _FakeWorkspaceRepository(),
      invitations,
      onMembershipChanged: (_, _) async =>
          const MembershipRefreshResult.failed(),
    )..bindUser('user-1');
    await _settle();
    expect(await cubit.decline(_invitation.id), isFalse);
    expect(cubit.state.invitations, [_invitation]);
    expect(cubit.state.failure?.message, 'Offline');
    expect(cubit.state.busy, isFalse);
    expect(cubit.state.respondingInvitationId, isNull);
    await cubit.close();
  });
  test('old refresh cannot restore a declined invitation', () async {
    final stale = Completer<List<WorkspaceRecord>>();
    final workspaces = _FakeWorkspaceRepository();
    final cubit = WorkspacesCubit(
      workspaces,
      _FakeInvitationRepository(),
      onMembershipChanged: (_, _) async =>
          const MembershipRefreshResult.failed(),
    )..bindUser('user-1');
    await _settle();
    workspaces.pendingList = stale.future;
    final oldLoad = cubit.load();
    expect(await cubit.decline(_invitation.id), isTrue);
    stale.complete([_workspace]);
    await oldLoad;
    expect(cubit.state.invitations, isEmpty);
    await cubit.close();
  });
  test('binding a user loads workspaces and personal invitations', () async {
    final workspaces = _FakeWorkspaceRepository();
    final invitations = _FakeInvitationRepository();
    final cubit = WorkspacesCubit(
      workspaces,
      invitations,
      onMembershipChanged: (_, _) async =>
          const MembershipRefreshResult.failed(),
    );

    cubit.bindUser('user-1');
    await _settle();

    expect(cubit.state.loading, isFalse);
    expect(cubit.state.workspaces, [_workspace]);
    expect(cubit.state.invitations, [_invitation]);
    await cubit.close();
  });

  test(
    'create succeeds across temporary unbind and same-user rebind',
    () async {
      late WorkspacesCubit cubit;
      cubit = WorkspacesCubit(
        _FakeWorkspaceRepository(),
        _FakeInvitationRepository(),
        onMembershipChanged: (workspaceId, expectedUserId) async {
          cubit.bindUser(null);
          cubit.bindUser(expectedUserId);
          return _authorized(workspaceId, userId: expectedUserId);
        },
      )..bindUser('user-1');
      await _settle();

      expect(await cubit.create(name: 'Shiftly Cairo'), isTrue);
      expect(cubit.state.creating, isFalse);
      await cubit.close();
    },
  );

  test(
    'accept succeeds across temporary unbind and same-user rebind',
    () async {
      late WorkspacesCubit cubit;
      cubit = WorkspacesCubit(
        _FakeWorkspaceRepository(),
        _FakeInvitationRepository(),
        onMembershipChanged: (workspaceId, expectedUserId) async {
          cubit.bindUser(null);
          cubit.bindUser(expectedUserId);
          return _authorized(
            workspaceId,
            userId: expectedUserId,
            role: WorkspaceRole.employee,
          );
        },
      )..bindUser('user-1');
      await _settle();

      expect(await cubit.accept('one-time-token'), isTrue);
      expect(cubit.state.accepting, isFalse);
      await cubit.close();
    },
  );

  test('logout during membership refresh cannot report success', () async {
    late WorkspacesCubit cubit;
    cubit = WorkspacesCubit(
      _FakeWorkspaceRepository(),
      _FakeInvitationRepository(),
      onMembershipChanged: (workspaceId, expectedUserId) async {
        cubit.bindUser(null);
        return const MembershipRefreshResult.failed();
      },
    )..bindUser('user-1');
    await _settle();

    expect(await cubit.create(name: 'Shiftly Cairo'), isFalse);
    expect(cubit.state.creating, isFalse);
    await cubit.close();
  });

  test(
    'switching users during membership refresh cannot report success',
    () async {
      late WorkspacesCubit cubit;
      cubit = WorkspacesCubit(
        _FakeWorkspaceRepository(),
        _FakeInvitationRepository(),
        onMembershipChanged: (workspaceId, expectedUserId) async {
          cubit.bindUser(null);
          cubit.bindUser('user-2');
          return _authorized(workspaceId, userId: expectedUserId);
        },
      )..bindUser('user-1');
      await _settle();

      expect(await cubit.accept('one-time-token'), isFalse);
      expect(cubit.state.accepting, isFalse);
      await cubit.close();
    },
  );

  test('membership refresh failure is returned as a real failure', () async {
    final cubit = WorkspacesCubit(
      _FakeWorkspaceRepository(),
      _FakeInvitationRepository(),
      onMembershipChanged: (_, _) async =>
          const MembershipRefreshResult.failed(),
    )..bindUser('user-1');
    await _settle();

    expect(await cubit.create(name: 'Shiftly Cairo'), isFalse);
    expect(await cubit.accept('one-time-token'), isFalse);
    await cubit.close();
  });

  test('backend create and acceptance failures remain failures', () async {
    final cubit = WorkspacesCubit(
      _FakeWorkspaceRepository(createError: const ApiException(message: 'x')),
      _FakeInvitationRepository(acceptError: const ApiException(message: 'x')),
      onMembershipChanged: (workspaceId, userId) async =>
          _authorized(workspaceId, userId: userId),
    )..bindUser('user-1');
    await _settle();

    expect(await cubit.create(name: 'Shiftly Cairo'), isFalse);
    expect(await cubit.accept('one-time-token'), isFalse);
    await cubit.close();
  });

  test(
    'duplicate create and accept submissions make one request each',
    () async {
      final createRefresh = Completer<MembershipRefreshResult>();
      final acceptRefresh = Completer<MembershipRefreshResult>();
      final workspaces = _FakeWorkspaceRepository();
      final invitations = _FakeInvitationRepository();
      final cubit = WorkspacesCubit(
        workspaces,
        invitations,
        onMembershipChanged: (workspaceId, userId) =>
            workspaceId == 'workspace-1'
            ? createRefresh.future
            : acceptRefresh.future,
      )..bindUser('user-1');
      await _settle();

      final create = cubit.create(name: 'Shiftly Cairo');
      await _settle();
      expect(await cubit.create(name: 'Duplicate'), isFalse);
      expect(workspaces.createCalls, 1);
      createRefresh.complete(_authorized('workspace-1'));
      expect(await create, isTrue);

      final accept = cubit.accept('one-time-token');
      await _settle();
      expect(await cubit.accept('duplicate-token'), isFalse);
      expect(invitations.acceptCalls, 1);
      acceptRefresh.complete(
        _authorized('workspace-2', role: WorkspaceRole.employee),
      );
      expect(await accept, isTrue);
      await cubit.close();
    },
  );

  test('logout clears data and ignores a stale load response', () async {
    final pending = Completer<List<WorkspaceRecord>>();
    final cubit = WorkspacesCubit(
      _FakeWorkspaceRepository(pendingList: pending.future),
      _FakeInvitationRepository(),
      onMembershipChanged: (_, _) async =>
          const MembershipRefreshResult.failed(),
    )..bindUser('user-1');
    await Future<void>.delayed(Duration.zero);

    cubit.bindUser(null);
    pending.complete(const [_workspace]);
    await _settle();

    expect(cubit.state.workspaces, isEmpty);
    expect(cubit.state.invitations, isEmpty);
    await cubit.close();
  });
}

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _FakeWorkspaceRepository implements WorkspaceRepository {
  _FakeWorkspaceRepository({this.pendingList, this.createError});

  Future<List<WorkspaceRecord>>? pendingList;
  final Object? createError;
  int createCalls = 0;

  @override
  Future<WorkspaceRecord> createWorkspace({
    required String name,
    String? timezone,
  }) async {
    createCalls += 1;
    if (createError case final Object error) throw error;
    return _workspace;
  }

  @override
  Future<WorkspaceRecord> getWorkspace(String workspaceId) async => _workspace;

  @override
  Future<List<WorkspaceRecord>> listWorkspaces() async =>
      pendingList ?? const [_workspace];
}

class _FakeInvitationRepository implements InvitationRepository {
  _FakeInvitationRepository({this.acceptError});

  final Object? acceptError;
  int acceptCalls = 0;
  String? acceptedId;
  String? declinedId;
  Future<void>? declineGate;
  List<WorkspaceInvitation> items = const [_invitation];
  @override
  Future<WorkspaceRecord> acceptInvitationById(String invitationId) {
    acceptedId = invitationId;
    return acceptInvitation(invitationId);
  }

  @override
  Future<void> declineInvitation(String invitationId) async {
    declinedId = invitationId;
    await declineGate;
    if (acceptError case final Object error) throw error;
    items = items.where((item) => item.id != invitationId).toList();
  }

  @override
  Future<WorkspaceRecord> acceptInvitation(String inviteToken) async {
    acceptCalls += 1;
    if (acceptError case final Object error) throw error;
    return const WorkspaceRecord(
      id: 'workspace-2',
      name: 'Accepted workspace',
      code: 'ACCEPTED',
      timezone: 'Africa/Cairo',
      role: WorkspaceAccessRole.employee,
      status: WorkspaceAccessStatus.active,
    );
  }

  @override
  Future<WorkspaceInvitation> createInvitation({
    required String workspaceId,
    required String email,
    String? jobTitle,
  }) => throw UnimplementedError();

  @override
  Future<List<WorkspaceInvitation>> listMyInvitations() async => items;

  @override
  Future<List<WorkspaceInvitation>> listWorkspaceInvitations({
    required String workspaceId,
    InvitationStatus? status,
  }) => throw UnimplementedError();
}
