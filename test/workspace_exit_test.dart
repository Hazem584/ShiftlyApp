import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/session/workspace_exit_session.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/workspaces/presentation/widgets/workspace_exit_dialog.dart';

WorkspaceMembership membership(String id, WorkspaceRole role) =>
    WorkspaceMembership(
      id: 'member-$id',
      role: role,
      status: MembershipStatus.active,
      workspace: Workspace(
        id: id,
        name: 'Workspace $id',
        code: 'CODE',
        timezone: 'UTC',
      ),
    );
SessionState session(List<WorkspaceMembership> memberships) => SessionState(
  status: SessionStatus.authenticatedEmployee,
  currentUser: CurrentUser(
    id: 'user',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    memberships: memberships,
  ),
  activeMembership: memberships.first,
);
void main() {
  test('last membership goes to invitations without signing out', () {
    final state = sessionWithoutWorkspace(
      session([membership('one', WorkspaceRole.employee)]),
      'one',
    );
    expect(state.status, SessionStatus.workspaceSelectionRequired);
    expect(state.currentUser!.id, 'user');
    expect(state.currentUser!.memberships, isEmpty);
    expect(state.activeMembership, isNull);
  });
  test(
    'leaving switches to another accessible workspace and keeps its role',
    () {
      final state = sessionWithoutWorkspace(
        session([
          membership('one', WorkspaceRole.employee),
          membership('two', WorkspaceRole.manager),
        ]),
        'one',
      );
      expect(state.status, SessionStatus.authenticatedManager);
      expect(state.activeMembership!.workspace.id, 'two');
    },
  );
  testWidgets('manager must type the exact name before permanent deletion', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WorkspaceExitDialog(workspaceName: 'Team Cairo', manager: true),
        ),
      ),
    );
    FilledButton button() =>
        tester.widget(find.byKey(const Key('confirm-leave-workspace')));
    expect(button().onPressed, isNull);
    await tester.enterText(
      find.byKey(const Key('workspace-delete-confirmation')),
      'Team',
    );
    await tester.pump();
    expect(button().onPressed, isNull);
    await tester.enterText(
      find.byKey(const Key('workspace-delete-confirmation')),
      'Team Cairo',
    );
    await tester.pump();
    expect(button().onPressed, isNotNull);
    expect(find.textContaining('for every member'), findsOneWidget);
  });
  testWidgets('employee sees leave, never a workspace delete form', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WorkspaceExitDialog(
            workspaceName: 'Team Cairo',
            manager: false,
          ),
        ),
      ),
    );
    expect(
      find.byKey(const Key('workspace-delete-confirmation')),
      findsNothing,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('confirm-leave-workspace')),
          )
          .onPressed,
      isNotNull,
    );
    expect(find.text('Permanently delete'), findsNothing);
  });
}
