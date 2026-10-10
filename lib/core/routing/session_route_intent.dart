import 'package:shiftly/core/session/session_state.dart';

/// Holds a browser entry URL while authentication restores the session.
class SessionRouteIntent {
  Uri? _destination;
  static const _public = {
    '/',
    '/session',
    '/onboarding',
    '/login',
    '/register',
    '/verify-email',
    '/profile-setup',
    '/offline',
    '/session-error',
  };

  void remember(Uri uri, SessionStatus status) {
    if (status != SessionStatus.initializing &&
        status != SessionStatus.loadingCurrentUser) {
      return;
    }
    if (!_public.contains(uri.path) &&
        !uri.hasAuthority &&
        uri.scheme.isEmpty) {
      _destination ??= uri;
    }
  }

  String? takeFor(SessionStatus status) {
    if (status != SessionStatus.authenticatedManager &&
        status != SessionStatus.authenticatedEmployee) {
      return null;
    }
    final destination = _destination;
    _destination = null;
    if (destination == null) return null;
    final employeeRoute =
        destination.path == '/employee' ||
        destination.path.startsWith('/employee/chat/');
    final sharedRoute = destination.path == '/workspaces';
    if (status == SessionStatus.authenticatedEmployee &&
        !employeeRoute &&
        !sharedRoute) {
      return null;
    }
    if (status == SessionStatus.authenticatedManager && employeeRoute) {
      return null;
    }
    return destination.toString();
  }
}
