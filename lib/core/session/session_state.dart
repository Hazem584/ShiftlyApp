import 'package:equatable/equatable.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';

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

class SessionState extends Equatable {
  const SessionState({
    required this.status,
    this.currentUser,
    this.activeMembership,
    this.failure,
    this.verificationEmail,
    this.resendingVerification = false,
  });

  const SessionState.initializing() : this(status: SessionStatus.initializing);

  final SessionStatus status;
  final CurrentUser? currentUser;
  final WorkspaceMembership? activeMembership;
  final Failure? failure;
  final String? verificationEmail;
  final bool resendingVerification;

  bool get isAuthenticated =>
      status == SessionStatus.authenticatedManager ||
      status == SessionStatus.authenticatedEmployee;

  @override
  List<Object?> get props => [
    status,
    currentUser,
    activeMembership,
    failure,
    verificationEmail,
    resendingVerification,
  ];
}
