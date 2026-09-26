import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/auth/data/supabase_authentication_service.dart';
import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_repository.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';

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
    emit(const SessionState(status: SessionStatus.authenticating));
    try {
      final result = await _authentication.signIn(
        email: email.trim().toLowerCase(),
        password: password,
      );
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
      emit(SessionState(status: SessionStatus.failure, failure: error.failure));
    } catch (_) {
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

  Future<void> bootstrapProfile({String? fullName, String? phone}) async {
    if (state.status == SessionStatus.loadingCurrentUser) return;
    final trimmedName = fullName?.trim();
    final trimmedPhone = phone?.trim();
    emit(const SessionState(status: SessionStatus.loadingCurrentUser));
    try {
      await _repository.bootstrapProfile(
        fullName: trimmedName,
        phone: trimmedPhone == null || trimmedPhone.isEmpty
            ? null
            : trimmedPhone,
      );
      await _resolveCurrentUser();
    } on ApiException catch (error) {
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

  Future<void> selectWorkspace(String workspaceId) async {
    final user = state.currentUser;
    if (user == null) return;
    final active = user.memberships.where(
      (item) =>
          item.status == MembershipStatus.active &&
          item.role != WorkspaceRole.unknown &&
          item.workspace.id == workspaceId,
    );
    if (active.length != 1) return;
    await _activate(user, active.single);
  }

  void synchronizeProfile(ManagerProfile profile) {
    final user = state.currentUser;
    if (user == null || profile.id != user.id) return;
    final updated = user.copyWithProfile(
      email: profile.email,
      fullName: profile.fullName,
      phone: profile.phone,
      avatarUrl: profile.avatarUrl,
      updatedAt: profile.updatedAt,
    );
    emit(
      SessionState(
        status: state.status,
        currentUser: updated,
        activeMembership: state.activeMembership,
        failure: state.failure,
      ),
    );
  }

  Future<void> signOut() async {
    _loggingOut = true;
    emit(const SessionState(status: SessionStatus.unauthenticated));
    try {
      await _authentication.signOut();
      await _workspaceStorage.clear();
    } finally {
      _loggingOut = false;
    }
  }

  Future<void> _resolveCurrentUser() async {
    if (_resolving) return;
    _resolving = true;
    emit(const SessionState(status: SessionStatus.loadingCurrentUser));
    try {
      final user = await _repository.loadCurrentUser();
      final memberships = user.memberships
          .where(
            (item) =>
                item.status == MembershipStatus.active &&
                item.role != WorkspaceRole.unknown,
          )
          .toList(growable: false);
      final savedId = await _workspaceStorage.read();
      if (memberships.isEmpty) {
        await _workspaceStorage.clear();
        emit(
          SessionState(
            status: SessionStatus.workspaceSelectionRequired,
            currentUser: user,
          ),
        );
      } else if (memberships.length == 1) {
        await _activate(user, memberships.single);
      } else {
        final restored = memberships.where(
          (item) => item.workspace.id == savedId,
        );
        if (restored.length == 1) {
          await _activate(user, restored.single);
        } else {
          if (savedId != null) await _workspaceStorage.clear();
          emit(
            SessionState(
              status: SessionStatus.workspaceSelectionRequired,
              currentUser: user,
            ),
          );
        }
      }
    } on ApiException catch (error) {
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
    WorkspaceMembership membership,
  ) async {
    await _workspaceStorage.write(membership.workspace.id);
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
    if (event.type != AuthenticationEventType.signedOut || _loggingOut) return;
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

  @override
  Future<void> close() async {
    await _authSubscription.cancel();
    return super.close();
  }
}
