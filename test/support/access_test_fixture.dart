import 'dart:async';

import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_repository.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';
import 'package:shiftly/features/invitations/data/mock_invitation_repository.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';
import 'package:shiftly/features/workspaces/data/mock_workspace_repository.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_repository.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_cubit.dart';

CurrentUser accessUser({bool unavailable = false}) => CurrentUser(
  id: 'access-user',
  email: 'omar.adel@example.com',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  memberships: [
    WorkspaceMembership(
      id: 'member-1',
      role: WorkspaceRole.employee,
      status: unavailable
          ? MembershipStatus.suspended
          : MembershipStatus.active,
      workspace: const Workspace(
        id: 'riverside',
        name: 'Riverside store',
        code: 'RIVER',
        timezone: 'Africa/Cairo',
      ),
    ),
    if (!unavailable)
      const WorkspaceMembership(
        id: 'member-2',
        role: WorkspaceRole.manager,
        status: MembershipStatus.active,
        workspace: Workspace(
          id: 'central',
          name: 'Central warehouse',
          code: 'CENTRAL',
          timezone: 'Africa/Cairo',
        ),
      ),
  ],
);

final accessInvitation = WorkspaceInvitation(
  id: 'invite',
  workspaceId: 'riverside',
  email: 'omar.adel@example.com',
  jobTitle: 'Warehouse associate',
  status: InvitationStatus.pending,
  createdAt: DateTime.utc(2026, 11, 1),
  expiresAt: DateTime.utc(2090, 11, 7),
  workspace: const WorkspaceRecord(
    id: 'riverside',
    name: 'Riverside store',
    code: 'RIVER',
    timezone: 'Africa/Cairo',
    role: WorkspaceAccessRole.employee,
    status: WorkspaceAccessStatus.invited,
  ),
);

class AccessTestAuth implements AuthenticationService {
  AuthSession? session;
  final events = StreamController<AuthenticationEvent>.broadcast();
  Completer<AuthenticationResult>? pending;
  int signIns = 0;
  @override
  AuthSession? get currentSession => session;
  @override
  Stream<AuthenticationEvent> get authStateChanges => events.stream;
  @override
  Future<AuthSession?> refreshSession() async => session;
  @override
  Future<void> signOut() async => session = null;
  @override
  Future<AuthenticationResult> signIn({
    required String email,
    required String password,
  }) async {
    signIns++;
    final result =
        await (pending?.future ??
            Future.value(
              const AuthenticationResult(
                session: AuthSession(accessToken: 'test'),
              ),
            ));
    session = result.session;
    return result;
  }

  @override
  Future<AuthenticationResult> signUp({
    required String email,
    required String password,
  }) async => const AuthenticationResult(
    session: null,
    emailVerificationRequired: true,
  );
  @override
  Future<void> resendSignUpVerification({required String email}) async {}
}

class AccessTestRepository implements AuthenticationRepository {
  Object? error;
  @override
  Future<CurrentUser> loadCurrentUser() async => accessUser();
  @override
  Future<void> bootstrapProfile({String? fullName, String? phone}) async {
    if (error != null) throw error!;
  }
}

class AccessTestSession extends SessionCoordinator {
  AccessTestSession(
    AuthenticationService auth,
    AuthenticationRepository repository,
  ) : super(auth, repository, MemoryActiveWorkspaceStorage());
  void show(SessionState value) => emit(value);
}

class AccessTestWorkspaces extends MockWorkspaceRepository {
  bool fail = false;
  Completer<void>? pending;
  int creates = 0;
  @override
  Future<WorkspaceRecord> createWorkspace({
    required String name,
    String? timezone,
  }) async {
    creates++;
    await pending?.future;
    if (fail) {
      throw const ApiException(
        message: 'Could not create workspace.',
        statusCode: 503,
      );
    }
    return super.createWorkspace(name: name, timezone: timezone);
  }
}

class AccessTestInvitations extends MockInvitationRepository {
  String? accepted, declined;
  @override
  Future<List<WorkspaceInvitation>> listMyInvitations() async =>
      declined == null ? [accessInvitation] : [];
  @override
  Future<void> declineInvitation(String invitationId) async {
    declined = invitationId;
  }

  @override
  Future<WorkspaceRecord> acceptInvitationById(String invitationId) async {
    accepted = invitationId;
    return super.acceptInvitationById(invitationId);
  }
}

class AccessTestFixture {
  AccessTestFixture() {
    session = AccessTestSession(auth, repository);
    workspaces = WorkspacesCubit(
      workspaceRepository,
      invitations,
      onMembershipChanged: (id, user) async =>
          MembershipRefreshResult.authorized(
            userId: user,
            workspaceId: id,
            role: WorkspaceRole.employee,
          ),
    )..bindUser('access-user');
  }
  final auth = AccessTestAuth();
  final repository = AccessTestRepository();
  final workspaceRepository = AccessTestWorkspaces();
  final invitations = AccessTestInvitations();
  late final AccessTestSession session;
  late final WorkspacesCubit workspaces;
  Future<void> close() async {
    await workspaces.close();
    await session.close();
    await auth.events.close();
  }
}
