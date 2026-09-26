import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/auth/data/supabase_authentication_service.dart';
import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_repository.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';

class _Auth implements AuthenticationService {
  AuthSession? session;
  AuthenticationResult signInResult = const AuthenticationResult(
    session: AuthSession(accessToken: 'token'),
  );
  int signInCalls = 0;
  int signOutCalls = 0;
  Object? signInError;
  final controller = StreamController<AuthenticationEvent>.broadcast();

  @override
  Stream<AuthenticationEvent> get authStateChanges => controller.stream;
  @override
  AuthSession? get currentSession => session;
  @override
  Future<AuthSession?> refreshSession() async => session;
  @override
  Future<AuthenticationResult> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    if (signInError case final Object error) throw error;
    session = signInResult.session;
    return signInResult;
  }

  @override
  Future<AuthenticationResult> signUp({
    required String email,
    required String password,
  }) async => signInResult;
  @override
  Future<void> signOut() async {
    signOutCalls++;
    session = null;
  }
}

class _Repository implements AuthenticationRepository {
  _Repository(this.result);
  Object result;
  int loads = 0;

  @override
  Future<void> bootstrapProfile({String? fullName, String? phone}) async {}
  @override
  Future<CurrentUser> loadCurrentUser() async {
    loads++;
    if (result is Exception) throw result as Exception;
    return result as CurrentUser;
  }
}

CurrentUser _user(List<WorkspaceMembership> memberships) => CurrentUser(
  id: 'profile',
  email: 'person@example.com',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  memberships: memberships,
);

WorkspaceMembership _membership(
  String id,
  WorkspaceRole role, {
  MembershipStatus status = MembershipStatus.active,
}) => WorkspaceMembership(
  role: role,
  status: status,
  workspace: Workspace(
    id: id,
    name: 'Workspace $id',
    code: id,
    timezone: 'Africa/Cairo',
  ),
);

Future<SessionCoordinator> _coordinator(
  _Auth auth,
  Object result,
  MemoryActiveWorkspaceStorage storage,
) async {
  final coordinator = SessionCoordinator(auth, _Repository(result), storage);
  addTearDown(coordinator.close);
  addTearDown(auth.controller.close);
  await coordinator.initialize();
  return coordinator;
}

void main() {
  test('no session routes to unauthenticated', () async {
    final coordinator = await _coordinator(
      _Auth(),
      _user([]),
      MemoryActiveWorkspaceStorage(),
    );
    expect(coordinator.state.status, SessionStatus.unauthenticated);
  });

  test('valid session loads current user and manager membership', () async {
    final auth = _Auth()..session = const AuthSession(accessToken: 'token');
    final coordinator = await _coordinator(
      auth,
      _user([_membership('one', WorkspaceRole.manager)]),
      MemoryActiveWorkspaceStorage(),
    );
    expect(coordinator.state.status, SessionStatus.authenticatedManager);
    expect(coordinator.state.activeMembership?.workspace.id, 'one');
  });

  test('employee membership routes to employee shell', () async {
    final auth = _Auth()..session = const AuthSession(accessToken: 'token');
    final coordinator = await _coordinator(
      auth,
      _user([_membership('one', WorkspaceRole.employee)]),
      MemoryActiveWorkspaceStorage(),
    );
    expect(coordinator.state.status, SessionStatus.authenticatedEmployee);
  });

  test('missing profile routes to profile setup', () async {
    final auth = _Auth()..session = const AuthSession(accessToken: 'token');
    final coordinator = await _coordinator(
      auth,
      const ApiException(
        statusCode: 409,
        code: 'PROFILE_NOT_INITIALIZED',
        message: 'setup',
      ),
      MemoryActiveWorkspaceStorage(),
    );
    expect(coordinator.state.status, SessionStatus.profileSetupRequired);
  });

  test('no active memberships routes to no-workspace selection', () async {
    final auth = _Auth()..session = const AuthSession(accessToken: 'token');
    final coordinator = await _coordinator(
      auth,
      _user([
        _membership(
          'one',
          WorkspaceRole.employee,
          status: MembershipStatus.suspended,
        ),
      ]),
      MemoryActiveWorkspaceStorage(),
    );
    expect(coordinator.state.status, SessionStatus.workspaceSelectionRequired);
    expect(coordinator.state.currentUser, isNotNull);
  });

  test(
    'multiple memberships restore a valid choice and clear a stale one',
    () async {
      final auth = _Auth()..session = const AuthSession(accessToken: 'token');
      final validStorage = MemoryActiveWorkspaceStorage()..value = 'two';
      final memberships = [
        _membership('one', WorkspaceRole.manager),
        _membership('two', WorkspaceRole.employee),
      ];
      final restored = await _coordinator(
        auth,
        _user(memberships),
        validStorage,
      );
      expect(restored.state.status, SessionStatus.authenticatedEmployee);

      final secondAuth = _Auth()
        ..session = const AuthSession(accessToken: 'token');
      final staleStorage = MemoryActiveWorkspaceStorage()..value = 'stale';
      final selecting = await _coordinator(
        secondAuth,
        _user(memberships),
        staleStorage,
      );
      expect(selecting.state.status, SessionStatus.workspaceSelectionRequired);
      expect(staleStorage.value, isNull);
    },
  );

  test(
    'offline startup remains retryable and logout clears selection',
    () async {
      final auth = _Auth()..session = const AuthSession(accessToken: 'token');
      final storage = MemoryActiveWorkspaceStorage()..value = 'one';
      final coordinator = await _coordinator(
        auth,
        const ApiException(message: 'offline', kind: FailureKind.network),
        storage,
      );
      expect(coordinator.state.status, SessionStatus.offlineWithSession);
      await coordinator.signOut();
      expect(coordinator.state.status, SessionStatus.unauthenticated);
      expect(storage.value, isNull);
    },
  );

  test('successful login resolves the backend user', () async {
    final auth = _Auth();
    final coordinator = SessionCoordinator(
      auth,
      _Repository(_user([_membership('one', WorkspaceRole.manager)])),
      MemoryActiveWorkspaceStorage(),
    );
    addTearDown(coordinator.close);
    addTearDown(auth.controller.close);
    await coordinator.initialize();
    await coordinator.signIn(
      email: ' PERSON@EXAMPLE.COM ',
      password: 'password',
    );
    expect(auth.signInCalls, 1);
    expect(coordinator.state.status, SessionStatus.authenticatedManager);
  });

  test('invalid credentials are exposed only as a safe failure', () async {
    final auth = _Auth()
      ..signInError = const AuthenticationException(
        Failure(
          message: 'The email or password is incorrect.',
          kind: FailureKind.authentication,
        ),
      );
    final coordinator = await _coordinator(
      auth,
      _user([]),
      MemoryActiveWorkspaceStorage(),
    );
    await coordinator.signIn(email: 'person@example.com', password: 'wrong');
    expect(coordinator.state.status, SessionStatus.failure);
    expect(
      coordinator.state.failure?.message,
      'The email or password is incorrect.',
    );
  });

  test('email confirmation response never calls the backend', () async {
    final auth = _Auth()
      ..signInResult = const AuthenticationResult(
        session: null,
        emailVerificationRequired: true,
      );
    final repository = _Repository(_user([]));
    final coordinator = SessionCoordinator(
      auth,
      repository,
      MemoryActiveWorkspaceStorage(),
    );
    addTearDown(coordinator.close);
    addTearDown(auth.controller.close);
    await coordinator.initialize();
    await coordinator.signIn(email: 'person@example.com', password: 'password');
    expect(coordinator.state.status, SessionStatus.emailVerificationRequired);
    expect(repository.loads, 0);
  });

  test('auth stream errors become a safe failure state', () async {
    final auth = _Auth();
    final coordinator = await _coordinator(
      auth,
      _user([]),
      MemoryActiveWorkspaceStorage(),
    );
    auth.controller.addError(Exception('private stream error'));
    await Future<void>.delayed(Duration.zero);
    expect(coordinator.state.status, SessionStatus.failure);
    expect(coordinator.state.failure?.message, isNot(contains('private')));
  });
}
