import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/features/invitations/data/invitation_repository.dart';
import 'package:shiftly/features/workspaces/data/workspace_repository.dart';
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

void main() {
  test('binding a user loads workspaces and personal invitations', () async {
    final workspaces = _FakeWorkspaceRepository();
    final invitations = _FakeInvitationRepository();
    final cubit = WorkspacesCubit(
      workspaces,
      invitations,
      onMembershipChanged: (_) async {},
    );

    cubit.bindUser('user-1');
    await _settle();

    expect(cubit.state.loading, isFalse);
    expect(cubit.state.workspaces, [_workspace]);
    expect(cubit.state.invitations, [_invitation]);
    await cubit.close();
  });

  test(
    'create and accept refresh membership with the returned workspace',
    () async {
      final changed = <String>[];
      final cubit = WorkspacesCubit(
        _FakeWorkspaceRepository(),
        _FakeInvitationRepository(),
        onMembershipChanged: (workspaceId) async => changed.add(workspaceId),
      )..bindUser('user-1');
      await _settle();

      expect(await cubit.create(name: 'Shiftly Cairo'), isTrue);
      expect(cubit.state.creating, isFalse);
      expect(await cubit.accept('one-time-token'), isTrue);
      expect(cubit.state.accepting, isFalse);
      expect(changed, ['workspace-1', 'workspace-2']);
      await cubit.close();
    },
  );

  test('logout clears data and ignores a stale load response', () async {
    final pending = Completer<List<WorkspaceRecord>>();
    final cubit = WorkspacesCubit(
      _FakeWorkspaceRepository(pendingList: pending.future),
      _FakeInvitationRepository(),
      onMembershipChanged: (_) async {},
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
  _FakeWorkspaceRepository({this.pendingList});

  final Future<List<WorkspaceRecord>>? pendingList;

  @override
  Future<WorkspaceRecord> createWorkspace({
    required String name,
    String? timezone,
  }) async => _workspace;

  @override
  Future<WorkspaceRecord> getWorkspace(String workspaceId) async => _workspace;

  @override
  Future<List<WorkspaceRecord>> listWorkspaces() async =>
      pendingList ?? const [_workspace];
}

class _FakeInvitationRepository implements InvitationRepository {
  @override
  Future<WorkspaceRecord> acceptInvitation(String inviteToken) async =>
      const WorkspaceRecord(
        id: 'workspace-2',
        name: 'Accepted workspace',
        code: 'ACCEPTED',
        timezone: 'Africa/Cairo',
        role: WorkspaceAccessRole.employee,
        status: WorkspaceAccessStatus.active,
      );

  @override
  Future<WorkspaceInvitation> createInvitation({
    required String workspaceId,
    required String email,
    String? jobTitle,
  }) => throw UnimplementedError();

  @override
  Future<List<WorkspaceInvitation>> listMyInvitations() async => const [
    _invitation,
  ];

  @override
  Future<List<WorkspaceInvitation>> listWorkspaceInvitations({
    required String workspaceId,
    InvitationStatus? status,
  }) => throw UnimplementedError();
}
