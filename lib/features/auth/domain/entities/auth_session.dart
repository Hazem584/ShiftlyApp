class AuthSession {
  const AuthSession({required this.accessToken});

  final String accessToken;
}

class AuthenticationResult {
  const AuthenticationResult({
    required this.session,
    this.emailVerificationRequired = false,
  });

  final AuthSession? session;
  final bool emailVerificationRequired;
}

enum AuthenticationEventType { signedIn, signedOut, tokenRefreshed, other }

class AuthenticationEvent {
  const AuthenticationEvent(this.type);

  final AuthenticationEventType type;
}
