part of '../../session_state.dart';

enum SessionStatus {
  initializing,
  unauthenticated,
  authenticating,
  registering,
  emailVerificationRequired,
  profileSetupRequired,
  loadingCurrentUser,
  workspaceSelectionRequired,
  authenticatedManager,
  authenticatedEmployee,
  offlineWithSession,
  sessionExpired,
  failure,
}
