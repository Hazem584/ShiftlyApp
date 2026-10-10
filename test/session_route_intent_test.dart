import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/routing/session_route_intent.dart';
import 'package:shiftly/core/session/session_state.dart';

void main() {
  test('workspace invitations entry survives restoration for either role', () {
    for (final status in [
      SessionStatus.authenticatedEmployee,
      SessionStatus.authenticatedManager,
    ]) {
      final intent = SessionRouteIntent();
      intent.remember(Uri.parse('/workspaces'), SessionStatus.initializing);
      expect(intent.takeFor(status), '/workspaces');
    }
  });
  test('manager entry URL survives loading and login with query intact', () {
    final intent = SessionRouteIntent();
    intent.remember(
      Uri.parse('/attendance/reports?period=monthly'),
      SessionStatus.initializing,
    );
    intent.remember(Uri.parse('/session'), SessionStatus.loadingCurrentUser);
    expect(intent.takeFor(SessionStatus.unauthenticated), isNull);
    expect(
      intent.takeFor(SessionStatus.authenticatedManager),
      '/attendance/reports?period=monthly',
    );
    expect(intent.takeFor(SessionStatus.authenticatedManager), isNull);
  });
  test('employee tab survives session restoration; manager destinations are dropped', () {
    final intent = SessionRouteIntent();
    intent.remember(
      Uri.parse('/employee?tab=shifts'),
      SessionStatus.initializing,
    );
    expect(
      intent.takeFor(SessionStatus.authenticatedEmployee),
      '/employee?tab=shifts',
    );
    intent.remember(Uri.parse('/employees'), SessionStatus.loadingCurrentUser);
    expect(intent.takeFor(SessionStatus.authenticatedEmployee), isNull);
  });
  test(
    'public and external entry URLs do not become redirect destinations',
    () {
      final intent = SessionRouteIntent();
      for (final path in [
        '/login',
        '/',
        'https://example.org/employees',
        '//example.org/employees',
      ]) {
        intent.remember(Uri.parse(path), SessionStatus.initializing);
      }
      expect(intent.takeFor(SessionStatus.authenticatedManager), isNull);
    },
  );
}
