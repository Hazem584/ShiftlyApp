import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/core/session/profile_session_update.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/auth/domain/entities/authentication_exception.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_repository.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';

import 'session_results.dart';
import 'workspace_membership_policy.dart';

export 'session_results.dart';

class SessionCoordinator extends Cubit<SessionState> {
  SessionCoordinator(
    this._authentication,
    this._repository,
    this._workspaceStorage,
  ) : super(const SessionState.initializing()) {
    _authSubscription = _authentication.authStateChanges.listen(
      _onAuthEvent,
      onError: (_) {
        if (!isClosed) {
          emit(
            const SessionState(
              status: SessionStatus.failure,
              failure: Failure(
                message: 'Authentication state could not be monitored.',
              ),
            ),
          );
        }
      },
    );
  }

  final AuthenticationService _authentication;
  final AuthenticationRepository _repository;
  final ActiveWorkspaceStorage _workspaceStorage;
  late final StreamSubscription<AuthenticationEvent> _authSubscription;
  bool _loggingOut = false;
  bool _resolving = false;
  bool _switchingWorkspace = false;
  var _resolutionGeneration = 0;
  var _authenticationGeneration = 0;

  Future<void> initialize() async {
    emit(const SessionState.initializing());
    if (_authentication.currentSession == null) {
      emit(const SessionState(status: SessionStatus.unauthenticated));
      return;
    }
    await _resolveCurrentUser();
  }

  Future<void> signIn({required String email, required String password}) async {
    if (state.status == SessionStatus.authenticating) return;
    final generation = ++_authenticationGeneration;
    emit(const SessionState(status: SessionStatus.authenticating));
    try {
      final result = await _authentication.signIn(
        email: email.trim().toLowerCase(),
        password: password,
      );
      if (!_authenticationIsCurrent(generation)) return;
      if (result.emailVerificationRequired) {
        emit(
          const SessionState(status: SessionStatus.emailVerificationRequired),
        );
        return;
      }
      if (result.session == null) {
        emit(
          const SessionState(
            status: SessionStatus.failure,
            failure: Failure(message: 'Sign in did not create a session.'),
          ),
        );
        return;
      }
      await _resolveCurrentUser();
    } on AuthenticationException catch (error) {
      if (!_authenticationIsCurrent(generation)) return;
      emit(SessionState(status: SessionStatus.failure, failure: error.failure));
    } catch (_) {
      if (!_authenticationIsCurrent(generation)) return;
      emit(
        const SessionState(
          status: SessionStatus.failure,
          failure: Failure(
            message: 'Unable to sign in. Check your connection and retry.',
            kind: FailureKind.network,
          ),
        ),
      );
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    if (state.status == SessionStatus.registering) return;
    final normalizedEmail = email.trim().toLowerCase();
    final generation = ++_authenticationGeneration;
    emit(const SessionState(status: SessionStatus.registering));
    try {
      final result = await _authentication.signUp(
        email: normalizedEmail,
        password: password,
      );
      if (!_authenticationIsCurrent(generation)) return;
      if (result.session != null) {
        await _resolveCurrentUser();
        return;
      }
      if (result.emailVerificationRequired) {
        emit(
          SessionState(
            status: SessionStatus.emailVerificationRequired,
            verificationEmail: normalizedEmail,
          ),
        );
        return;
      }
      emit(
        const SessionState(
          status: SessionStatus.failure,
          failure: Failure(
            message:
                'Account creation could not be completed. Please try again.',
          ),
        ),
      );
    } on AuthenticationException catch (error) {
      if (!_authenticationIsCurrent(generation)) return;
      emit(SessionState(status: SessionStatus.failure, failure: error.failure));
    } catch (_) {
      if (!_authenticationIsCurrent(generation)) return;
      emit(
        const SessionState(
          status: SessionStatus.failure,
          failure: Failure(
            message: 'Unable to create your account. Check your connection and retry.',
            kind: FailureKind.network,
          ),
        ),
      );
    }
  }

  Future<bool> resendVerificationEmail() async {
    final email = state.verificationEmail;
    if (state.status != SessionStatus.emailVerificationRequired ||
        state.resendingVerification ||
        email == null) {
      return false;
    }
    final generation = _authenticationGeneration;
    emit(
      SessionState(
        status: SessionStatus.emailVerificationRequired,
        verificationEmail: email,
        resendingVerification: true,
      ),
    );
    try {
      await _authentication.resendSignUpVerification(email: email);
      if (!_authenticationIsCurrent(generation)) return false;
      emit(
        SessionState(
          status: SessionStatus.emailVerificationRequired,
          verificationEmail: email,
        ),
      );
      return true;
    } on AuthenticationException catch (error) {
      if (!_authenticationIsCurrent(generation)) return false;
      emit(
        SessionState(
          status: SessionStatus.emailVerificationRequired,
          verificationEmail: email,
          failure: error.failure,
        ),
      );
      return false;
    } catch (_) {
      if (!_authenticationIsCurrent(generation)) return false;
      emit(
        SessionState(
          status: SessionStatus.emailVerificationRequired,
          verificationEmail: email,
          failure: const Failure(
            message:
                'Unable to resend the email. Check your connection and retry.',
            kind: FailureKind.network,
          ),
        ),
      );
      return false;
    }
  }

  Future<void> bootstrapProfile({String? fullName, String? phone}) async {
    if (state.status == SessionStatus.loadingCurrentUser) return;
    final trimmedName = fullName?.trim();
    final trimmedPhone = phone?.trim();
    final generation = _authenticationGeneration;
    emit(const SessionState(status: SessionStatus.loadingCurrentUser));
    try {
      await _repository.bootstrapProfile(
        fullName: trimmedName,
        phone: trimmedPhone == null || trimmedPhone.isEmpty
            ? null
            : trimmedPhone,
      );
      if (!_authenticationIsCurrent(generation) ||
          _authentication.currentSession == null) {
        return;
      }
      await _resolveCurrentUser();
    } on ApiException catch (error) {
      if (!_authenticationIsCurrent(generation)) return;
      emit(
        SessionState(status: SessionStatus.failure, failure: error.toFailure()),
      );
    }
  }

  Future<void> retry() async {
    if (_authentication.currentSession == null) {
      emit(const SessionState(status: SessionStatus.unauthenticated));
      return;
    }
    await _resolveCurrentUser();
  }

  Future<MembershipRefreshResult> refreshMemberships({
    required String preferredWorkspaceId,
    required String expectedUserId,
  }) async {
    if (_authentication.currentSession == null) {
      emit(const SessionState(status: SessionStatus.unauthenticated));
      return const MembershipRefreshResult.failed();
    }
    await _resolveCurrentUser(preferredWorkspaceId: preferredWorkspaceId);
    final user = state.currentUser;
    final membership = state.activeMembership;
    if (!state.isAuthenticated ||
        user?.id != expectedUserId ||
        membership?.workspace.id != preferredWorkspaceId ||
        membership?.status != MembershipStatus.active ||
        membership?.role == WorkspaceRole.unknown) {
      return const MembershipRefreshResult.failed();
    }
    return MembershipRefreshResult.authorized(
      userId: user!.id,
      workspaceId: membership!.workspace.id,
      role: membership.role,
    );
  }

  List<WorkspaceMembership> get selectableMemberships =>
      activeWorkspaceMemberships(state.currentUser?.memberships ?? const []);

  Future<WorkspaceSwitchResult> selectWorkspace(String workspaceId) =>
      _switchWorkspace(workspaceId, requireAlternative: false);

  Future<WorkspaceSwitchResult> switchWorkspace(String workspaceId) =>
      _switchWorkspace(workspaceId, requireAlternative: true);

  Future<WorkspaceSwitchResult> _switchWorkspace(
    String workspaceId, {
    required bool requireAlternative,
  }) async {
    if (_switchingWorkspace) return WorkspaceSwitchResult.busy;
    final user = state.currentUser;
    if (user == null || _authentication.currentSession == null) {
      return WorkspaceSwitchResult.invalid;
    }
    final memberships = selectableMemberships;
    final currentId = state.activeMembership?.workspace.id;
    final alternatives = memberships.where(
      (item) => item.workspace.id != currentId,
    );
    if (requireAlternative && alternatives.isEmpty) {
      return WorkspaceSwitchResult.noAlternative;
    }
    final matches = memberships.where(
      (item) =>
          item.workspace.id == workspaceId && item.workspace.id != currentId,
    );
    if (matches.length != 1) return WorkspaceSwitchResult.invalid;
    final previous = state;
    final generation = ++_resolutionGeneration;
    _switchingWorkspace = true;
    emit(
      SessionState(status: SessionStatus.loadingCurrentUser, currentUser: user),
    );
    try {
      await _activate(user, matches.single, resolutionGeneration: generation);
      return _resolutionIsCurrent(generation) &&
              state.activeMembership?.workspace.id == workspaceId
          ? WorkspaceSwitchResult.success
          : WorkspaceSwitchResult.invalid;
    } catch (_) {
      if (_resolutionIsCurrent(generation)) emit(previous);
      return WorkspaceSwitchResult.failure;
    } finally {
      _switchingWorkspace = false;
    }
  }

  void synchronizeProfile(ManagerProfile profile) {
    final updated = sessionWithUpdatedProfile(state, profile);
    if (updated != null) emit(updated);
  }

  Future<void> signOut() async {
    _loggingOut = true;
    _authenticationGeneration += 1;
    _resolutionGeneration += 1;
    emit(const SessionState(status: SessionStatus.unauthenticated));
    try {
      await _authentication.signOut();
      await _workspaceStorage.clear();
    } finally {
      _loggingOut = false;
    }
  }

  Future<void> _resolveCurrentUser({String? preferredWorkspaceId}) async {
    if (_resolving) return;
    _resolving = true;
    final generation = ++_resolutionGeneration;
    emit(const SessionState(status: SessionStatus.loadingCurrentUser));
    try {
      final user = await _repository.loadCurrentUser();
      if (!_resolutionIsCurrent(generation)) return;
      final memberships = activeWorkspaceMemberships(user.memberships);
      final savedId = preferredWorkspaceId ?? await _workspaceStorage.read();
      if (!_resolutionIsCurrent(generation)) return;
      if (memberships.isEmpty) {
        await _workspaceStorage.clear();
        if (!_resolutionIsCurrent(generation)) return;
        emit(
          SessionState(
            status: SessionStatus.workspaceSelectionRequired,
            currentUser: user,
          ),
        );
      } else if (memberships.length == 1) {
        await _activate(
          user,
          memberships.single,
          resolutionGeneration: generation,
        );
      } else {
        final restored = memberships.where(
          (item) => item.workspace.id == savedId,
        );
        if (restored.length == 1) {
          await _activate(
            user,
            restored.single,
            resolutionGeneration: generation,
          );
        } else {
          if (savedId != null) await _workspaceStorage.clear();
          if (!_resolutionIsCurrent(generation)) return;
          emit(
            SessionState(
              status: SessionStatus.workspaceSelectionRequired,
              currentUser: user,
            ),
          );
        }
      }
    } on ApiException catch (error) {
      if (!_resolutionIsCurrent(generation)) return;
      if (error.code == 'PROFILE_NOT_INITIALIZED') {
        emit(const SessionState(status: SessionStatus.profileSetupRequired));
      } else if (error.kind == FailureKind.network ||
          error.kind == FailureKind.timeout) {
        emit(
          SessionState(
            status: SessionStatus.offlineWithSession,
            failure: error.toFailure(),
          ),
        );
      } else if (error.statusCode == 401) {
        await _clearExpiredAuthentication();
        emit(const SessionState(status: SessionStatus.sessionExpired));
        emit(
          const SessionState(
            status: SessionStatus.unauthenticated,
            failure: Failure(
              message: 'Your session has expired. Please sign in again.',
              kind: FailureKind.authentication,
            ),
          ),
        );
      } else {
        emit(
          SessionState(
            status: SessionStatus.failure,
            failure: error.toFailure(),
          ),
        );
      }
    } finally {
      _resolving = false;
    }
  }

  Future<void> _clearExpiredAuthentication() async {
    _loggingOut = true;
    _resolutionGeneration += 1;
    try {
      if (_authentication.currentSession != null) {
        await _authentication.signOut();
      }
      await _workspaceStorage.clear();
    } finally {
      _loggingOut = false;
    }
  }

  Future<void> _activate(
    CurrentUser user,
    WorkspaceMembership membership, {
    int? resolutionGeneration,
  }) async {
    if (resolutionGeneration != null &&
        !_resolutionIsCurrent(resolutionGeneration)) {
      return;
    }
    await _workspaceStorage.write(membership.workspace.id);
    if (resolutionGeneration != null &&
        !_resolutionIsCurrent(resolutionGeneration)) {
      await _workspaceStorage.clear();
      return;
    }
    emit(
      SessionState(
        status: membership.role == WorkspaceRole.manager
            ? SessionStatus.authenticatedManager
            : SessionStatus.authenticatedEmployee,
        currentUser: user,
        activeMembership: membership,
      ),
    );
  }

  void _onAuthEvent(AuthenticationEvent event) {
    if (event.type == AuthenticationEventType.signedIn &&
        state.status == SessionStatus.emailVerificationRequired &&
        _authentication.currentSession != null) {
      _authenticationGeneration += 1;
      unawaited(_resolveCurrentUser());
      return;
    }
    if (event.type != AuthenticationEventType.signedOut || _loggingOut) return;
    _authenticationGeneration += 1;
    _resolutionGeneration += 1;
    unawaited(_workspaceStorage.clear());
    emit(const SessionState(status: SessionStatus.sessionExpired));
    scheduleMicrotask(() {
      if (!isClosed && state.status == SessionStatus.sessionExpired) {
        emit(
          const SessionState(
            status: SessionStatus.unauthenticated,
            failure: Failure(
              message: 'Your session has expired. Please sign in again.',
              kind: FailureKind.authentication,
            ),
          ),
        );
      }
    });
  }

  bool _resolutionIsCurrent(int generation) =>
      !isClosed && _resolutionGeneration == generation;

  bool _authenticationIsCurrent(int generation) =>
      !isClosed && _authenticationGeneration == generation;

  @override
  Future<void> close() async {
    await _authSubscription.cancel();
    return super.close();
  }
}
