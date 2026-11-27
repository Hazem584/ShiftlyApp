import 'package:go_router/go_router.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/features/onboarding/presentation/cubit/onboarding_cubit.dart';

String? resolveAppRedirect(
  SessionCoordinator coordinator,
  GoRouterState route,
  OnboardingCubit? onboarding,
) {
  final status = coordinator.state.status;
  final location = route.matchedLocation;
  return switch (status) {
    SessionStatus.initializing || SessionStatus.loadingCurrentUser =>
      location == '/session' ? null : '/session',
    SessionStatus.unauthenticated => _signedOutRedirect(
      location,
      coordinator.state.failure?.kind == FailureKind.authentication
          ? null
          : onboarding,
    ),
    SessionStatus.sessionExpired =>
      location == '/login' || location == '/register' ? null : '/login',
    SessionStatus.authenticating => location == '/login' ? null : '/login',
    SessionStatus.registering => location == '/register' ? null : '/register',
    SessionStatus.emailVerificationRequired =>
      location == '/verify-email' ? null : '/verify-email',
    SessionStatus.profileSetupRequired =>
      location == '/profile-setup' || location == '/devices'
          ? null
          : '/profile-setup',
    SessionStatus.workspaceSelectionRequired =>
      location == '/workspaces' || location == '/devices'
          ? null
          : '/workspaces',
    SessionStatus.offlineWithSession =>
      location == '/offline' ? null : '/offline',
    SessionStatus.failure =>
      location == '/login' ||
              location == '/register' ||
              location == '/session-error'
          ? null
          : '/session-error',
    SessionStatus.authenticatedManager => _managerRedirect(location),
    SessionStatus.authenticatedEmployee =>
      location == '/support' ||
              location.startsWith('/support/') ||
              location == '/devices' ||
              location == '/tasks' ||
              location == '/team-work' ||
              location == '/workspaces' ||
              location == '/employee' ||
              location.startsWith('/employee/chat/')
          ? null
          : '/employee',
  };
}

String? _managerRedirect(String location) {
  if (location.startsWith('/employee/')) return '/dashboard';
  const public = {
    '/session',
    '/onboarding',
    '/login',
    '/register',
    '/verify-email',
    '/profile-setup',
    '/offline',
    '/session-error',
    '/employee',
  };
  return public.contains(location) ? '/dashboard' : null;
}

String? _signedOutRedirect(String location, OnboardingCubit? onboarding) {
  if (onboarding != null &&
      !onboarding.bypassed &&
      !onboarding.state.completed) {
    final target = onboarding.state.loading ? '/session' : '/onboarding';
    return location == target ? null : target;
  }
  return location == '/login' || location == '/register' ? null : '/login';
}
