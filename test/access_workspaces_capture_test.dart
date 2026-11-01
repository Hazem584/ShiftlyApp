import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/features/auth/presentation/screens/create_workspace_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/invitation_details_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/join_workspace_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/login_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/my_invitations_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/profile_setup_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/register_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/session_status_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/workspace_selection_screen.dart';
import 'package:shiftly/features/auth/presentation/widgets/workspace_switcher_sheet.dart';

import 'support/access_harness.dart';
import 'support/access_test_fixture.dart';

void main() {
  testWidgets(
    'Access & Workspaces render references, compact RTL, keyboard and large text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      for (final entry in const {
        'AccessInter': 'assets/access/fonts/InterTight-Variable.ttf',
        'AccessArabic': 'assets/access/fonts/NotoSansArabic-Variable.ttf',
      }.entries) {
        final loader = FontLoader(entry.key)
          ..addFont(rootBundle.load(entry.value));
        await loader.load();
      }
      final f = AccessTestFixture();
      addTearDown(f.close);
      final output = Directory('.artifacts/access-workspaces')
        ..createSync(recursive: true);
      final screens = <String, Widget Function()>{
        'A02-restoring': () => const SessionStatusScreen.loading(),
        'A06-sign-in': () => const LoginScreen(),
        'A07-register': () => const RegisterScreen(),
        'A08-verify': () => const EmailVerificationScreen(),
        'A09-profile': () => const ProfileSetupScreen(),
        'A10-workspaces': () => const WorkspaceSelectionScreen(),
        'A11-create': () => const CreateWorkspaceScreen(),
        'A12-invitations': () => const MyInvitationsScreen(),
        'A13-invitation': () =>
            InvitationDetailsScreen(invitation: accessInvitation),
        'A14-token': () => const JoinWorkspaceScreen(),
        'A15-expired': () => const LoginScreen(),
        'A16-offline': () => const SessionStatusScreen.offline(),
        'A17-unavailable': () => const WorkspaceSelectionScreen(),
        'A18-service': () => const SessionStatusScreen.failure(),
        'workspace-switcher': () =>
            Scaffold(body: WorkspaceSwitcherSheet(coordinator: f.session)),
      };
      for (final entry in screens.entries) {
        for (final variant in ['reference', 'compact-ar', 'desktop-dark']) {
          final compact = variant == 'compact-ar';
          final desktop = variant == 'desktop-dark';
          final width = compact
              ? 320.0
              : desktop
              ? 1280.0
              : 390.0;
          final height = desktop ? 900.0 : 844.0;
          tester.view.physicalSize = Size(width, height);
          final state = entry.key.startsWith('A15')
              ? const SessionState.expired()
              : entry.key.startsWith('A08')
              ? const SessionState(
                  status: SessionStatus.emailVerificationRequired,
                  verificationEmail: 'omar.adel@example.com',
                )
              : SessionState(
                  status: SessionStatus.workspaceSelectionRequired,
                  currentUser: accessUser(
                    unavailable: entry.key.startsWith('A17'),
                  ),
                );
          f.session.show(state);
          final key = GlobalKey();
          await tester.pumpWidget(
            accessHarness(
              f,
              entry.value(),
              boundary: key,
              language: compact ? 'ar' : 'en',
              dark: desktop,
              scale: compact ? 1.6 : 1,
            ),
          );
          await tester.pump(const Duration(milliseconds: 400));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump();
          expect(
            tester.takeException(),
            isNull,
            reason: '${entry.key} / $variant',
          );
          final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1).timeout(const Duration(seconds: 15));
            try {
              final bytes = await image.toByteData(format: ui.ImageByteFormat.png).timeout(const Duration(seconds: 15));
              await File('${output.path}/${entry.key}-$variant.png').writeAsBytes(bytes!.buffer.asUint8List());
            } finally { image.dispose(); }
          });
          await tester.pumpWidget(const SizedBox());
          await tester.pump();
        }
      }
      // Recoverable failure and keyboard-open form use actual field state.
      f.session.show(
        const SessionState(
          status: SessionStatus.unauthenticated,
          failure: Failure(
            message: 'Unable to sign in. Check your connection and retry.',
            requestId: 'sample-request',
          ),
        ),
      );
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpWidget(
        accessHarness(
          f,
          const LoginScreen(),
          insets: const EdgeInsets.only(bottom: 300),
        ),
      );
      await tester.enterText(
        find.byKey(const Key('login-email')),
        'long.email.address@example.com',
      );
      await tester.ensureVisible(find.byKey(const Key('login-password')));
      await tester.tap(find.byKey(const Key('login-password')));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
}
