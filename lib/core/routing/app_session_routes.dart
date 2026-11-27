import 'package:go_router/go_router.dart';
import 'package:shiftly/core/theme/collaboration_appearance.dart';
import 'package:shiftly/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/login_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/profile_setup_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/register_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/session_status_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/workspace_selection_screen.dart';
import 'package:shiftly/features/onboarding/presentation/screens/onboarding_screen.dart';

List<RouteBase> buildSessionAppRoutes() => [
  GoRoute(
    path: '/session',
    builder: (_, _) => const SessionStatusScreen.loading(),
  ),
  GoRoute(
    path: '/onboarding',
    builder: (_, _) => const CollaborationAppearance(child: OnboardingScreen()),
  ),
  GoRoute(
    path: '/login',
    builder: (_, _) => const CollaborationAppearance(child: LoginScreen()),
  ),
  GoRoute(
    path: '/register',
    builder: (_, _) => const CollaborationAppearance(child: RegisterScreen()),
  ),
  GoRoute(
    path: '/verify-email',
    builder: (_, _) => const EmailVerificationScreen(),
  ),
  GoRoute(
    path: '/profile-setup',
    builder: (_, _) =>
        const CollaborationAppearance(child: ProfileSetupScreen()),
  ),
  GoRoute(
    path: '/workspaces',
    builder: (_, _) =>
        const CollaborationAppearance(child: WorkspaceSelectionScreen()),
  ),
  GoRoute(
    path: '/offline',
    builder: (_, _) => const SessionStatusScreen.offline(),
  ),
  GoRoute(
    path: '/session-error',
    builder: (_, _) => const SessionStatusScreen.failure(),
  ),
];
