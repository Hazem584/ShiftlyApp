import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/features/auth/domain/entities/authentication_exception.dart';
import 'package:shiftly/features/auth/domain/entities/authentication_result.dart';
import 'package:shiftly/features/auth/presentation/screens/create_workspace_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/invitation_details_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/join_workspace_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/login_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/profile_setup_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/workspace_selection_screen.dart';

import 'support/access_harness.dart';
import 'support/access_test_fixture.dart';

void main() {
  testWidgets(
    'sign in keeps entered values on error and blocks duplicate submissions',
    (tester) async {
      final f = AccessTestFixture();
      addTearDown(f.close);
      f.session.show(const SessionState(status: SessionStatus.unauthenticated));
      f.auth.pending = Completer<AuthenticationResult>();
      await tester.pumpWidget(accessHarness(f, const LoginScreen()));
      await tester.enterText(
        find.byKey(const Key('login-email')),
        'person@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('login-password')),
        'private-password',
      );
      await tester.ensureVisible(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pump();
      expect(f.auth.signIns, 1);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('login-submit')))
            .onPressed,
        isNull,
      );
      f.auth.pending!.completeError(
        const AuthenticationException(
          Failure(
            message: 'Unable to sign in.',
            requestId: 'request-42',
            kind: FailureKind.network,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('login-email')))
            .controller!
            .text,
        'person@example.com',
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('login-password')))
            .controller!
            .text,
        'private-password',
      );
      expect(find.text('Request ID: request-42'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'create workspace validates and retains fields when the API rejects it',
    (tester) async {
      final f = AccessTestFixture();
      addTearDown(f.close);
      f.session.show(
        SessionState(
          status: SessionStatus.workspaceSelectionRequired,
          currentUser: accessUser(),
        ),
      );
      f.workspaceRepository.fail = true;
      await tester.pumpWidget(accessHarness(f, const CreateWorkspaceScreen()));
      await tester.ensureVisible(find.byKey(const Key('submit-workspace')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('submit-workspace')));
      await tester.pump();
      expect(find.text('Workspace name is required'), findsOneWidget);
      expect(f.workspaceRepository.creates, 0);
      await tester.enterText(
        find.byKey(const Key('workspace-name')),
        'Night team',
      );
      await tester.ensureVisible(find.byKey(const Key('submit-workspace')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('submit-workspace')));
      await tester.pumpAndSettle();
      expect(f.workspaceRepository.creates, 1);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('workspace-name')))
            .controller!
            .text,
        'Night team',
      );
      expect(find.text('Could not create workspace.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('profile name validation prevents empty bootstrap', (
    tester,
  ) async {
    final f = AccessTestFixture();
    addTearDown(f.close);
    f.session.show(
      const SessionState(status: SessionStatus.profileSetupRequired),
    );
    await tester.pumpWidget(accessHarness(f, const ProfileSetupScreen()));
    await tester.ensureVisible(find.byKey(const Key('profile-setup-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-setup-submit')));
    await tester.pump();
    expect(find.text('Full name is required'), findsOneWidget);
    expect(f.session.state.status, SessionStatus.profileSetupRequired);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('token validation is local and token stays obscured by default', (
    tester,
  ) async {
    final f = AccessTestFixture();
    addTearDown(f.close);
    f.session.show(
      SessionState(
        status: SessionStatus.workspaceSelectionRequired,
        currentUser: accessUser(),
      ),
    );
    await tester.pumpWidget(accessHarness(f, const JoinWorkspaceScreen()));
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const Key('invitation-token-field')),
              matching: find.byType(EditableText),
            ),
          )
          .obscureText,
      isTrue,
    );
    await tester.ensureVisible(find.byKey(const Key('accept-invitation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('accept-invitation')));
    await tester.pump();
    expect(find.text('Invitation token is required'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  for (final accept in [true, false]) {
    testWidgets(
      'invitation details invokes the real cubit ${accept ? 'accept' : 'decline'} action',
      (tester) async {
        final f = AccessTestFixture();
        addTearDown(f.close);
        f.session.show(
          SessionState(
            status: SessionStatus.workspaceSelectionRequired,
            currentUser: accessUser(),
          ),
        );
        await tester.pumpWidget(
          accessHarness(
            f,
            Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<String>(
                      builder: (_) =>
                          InvitationDetailsScreen(invitation: accessInvitation),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        final target = find.byKey(
          Key('${accept ? 'accept' : 'decline'}-invitation-invite'),
        );
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(
          accept ? f.invitations.accepted : f.invitations.declined,
          'invite',
        );
        expect(find.text('Open'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'create form owns controllers through its route closing transition',
    (tester) async {
      final f = AccessTestFixture();
      addTearDown(f.close);
      f.session.show(
        SessionState(
          status: SessionStatus.workspaceSelectionRequired,
          currentUser: accessUser(),
        ),
      );
      await tester.pumpWidget(
        accessHarness(f, const WorkspaceSelectionScreen()),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('create-workspace')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('create-workspace')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('workspace-name')),
        'Unsent team',
      );
      await tester.pageBack();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
