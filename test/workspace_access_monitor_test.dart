import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/offline/saved_read_store.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/session/workspace_access_monitor.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_repository.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';

class Auth implements AuthenticationService {
  @override
  AuthSession? get currentSession => const AuthSession(accessToken: 'test');
  @override
  Stream<AuthenticationEvent> get authStateChanges => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

CurrentUser user(String id) => CurrentUser(
  id: id,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  memberships: [
    const WorkspaceMembership(
      id: 'm',
      role: WorkspaceRole.employee,
      status: MembershipStatus.active,
      workspace: Workspace(id: 'w', name: 'Team', code: 'W', timezone: 'UTC'),
    ),
  ],
);

class Repo implements AuthenticationRepository {
  CurrentUser current = user('one');
  @override
  Future<CurrentUser> loadCurrentUser() async => current;
  @override
  Future<void> bootstrapProfile({String? fullName, String? phone}) async {}
}

class Adapter implements HttpClientAdapter {
  Future<ResponseBody> Function(RequestOptions) respond;
  Adapter(this.respond);
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) => respond(o);
  @override
  void close({bool force = false}) {}
}

ResponseBody body(int status, String code) => ResponseBody.fromString(
  jsonEncode({'code': code}),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);
void main() {
  test('confirmed remote removal leaves the workspace, not the authenticated account', () async {
    final repo = Repo(),
        c = SessionCoordinator(Auth(), Repo(), MemoryActiveWorkspaceStorage());
    await c.initialize();
    final api = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
      ..httpClientAdapter = Adapter(
        (_) async => body(404, 'WORKSPACE_NOT_FOUND'),
      );
    final monitor = WorkspaceAccessMonitor(api, c, SavedReadStore());
    await monitor.check();
    await Future<void>.delayed(Duration.zero);
    expect(c.state.status, SessionStatus.workspaceSelectionRequired);
    expect(c.state.currentUser!.id, repo.current.id);
    monitor.dispose();
    api.close();
    await c.close();
  });
  test('network/server errors never revoke workspace membership', () async {
    final c = SessionCoordinator(
      Auth(),
      Repo(),
      MemoryActiveWorkspaceStorage(),
    );
    await c.initialize();
    final api = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
      ..httpClientAdapter = Adapter((_) async => body(503, 'UNAVAILABLE'));
    final monitor = WorkspaceAccessMonitor(api, c, SavedReadStore());
    await monitor.check();
    expect(c.state.status, SessionStatus.authenticatedEmployee);
    monitor.dispose();
    api.close();
    await c.close();
  });
  test('an old account response cannot remove the next account from the same workspace', () async {
    final repo = Repo(),
        c = SessionCoordinator(Auth(), Repo(), MemoryActiveWorkspaceStorage());
    final actual = SessionCoordinator(
      Auth(),
      repo,
      MemoryActiveWorkspaceStorage(),
    );
    await actual.initialize();
    final gate = Completer<ResponseBody>(), started = Completer<void>();
    final api = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
      ..httpClientAdapter = Adapter((_) {
        started.complete();
        return gate.future;
      });
    final monitor = WorkspaceAccessMonitor(api, actual, SavedReadStore());
    final pending = monitor.check();
    await started.future;
    repo.current = user('two');
    await actual.retry();
    gate.complete(body(403, 'WORKSPACE_ACCESS_DENIED'));
    await pending;
    await Future<void>.delayed(Duration.zero);
    expect(actual.state.currentUser!.id, 'two');
    expect(actual.state.status, SessionStatus.authenticatedEmployee);
    monitor.dispose();
    api.close();
    await actual.close();
    await c.close();
  });
}
