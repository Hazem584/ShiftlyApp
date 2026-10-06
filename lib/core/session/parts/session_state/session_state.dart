part of '../../session_state.dart';

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
