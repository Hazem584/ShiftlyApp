import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/session_resolution_actions.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_repository.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';

abstract class SessionCoordinatorCubit extends Cubit<SessionState> {
  SessionCoordinatorCubit(
    this.authentication,
    this.repository,
    this.workspaceStorage,
  ) : super(const SessionState.initializing()) {
    hasObservedSession = authentication.currentSession != null;
    authSubscription = authentication.authStateChanges.listen(
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

  final AuthenticationService authentication;
  final AuthenticationRepository repository;
  final ActiveWorkspaceStorage workspaceStorage;
  late final StreamSubscription<AuthenticationEvent> authSubscription;
  bool loggingOut = false;
  late bool hasObservedSession;
  bool resolving = false;
  bool switchingWorkspace = false;
  var resolutionGeneration = 0;
  var authenticationGeneration = 0;

  void updateState(SessionState next) => emit(next);

  bool resolutionIsCurrent(int generation) =>
      !isClosed && resolutionGeneration == generation;

  bool authenticationIsCurrent(int generation) =>
      !isClosed && authenticationGeneration == generation;

  void _onAuthEvent(AuthenticationEvent event) {
    if (event.type == AuthenticationEventType.signedIn &&
        authentication.currentSession != null) {
      hasObservedSession = true;
    }
    if (event.type == AuthenticationEventType.signedIn &&
        state.status == SessionStatus.emailVerificationRequired &&
        authentication.currentSession != null) {
      authenticationGeneration += 1;
      unawaited(resolveSessionCurrentUser(this));
      return;
    }
    if (event.type != AuthenticationEventType.signedOut ||
        loggingOut ||
        !hasObservedSession) {
      return;
    }
    hasObservedSession = false;
    authenticationGeneration += 1;
    resolutionGeneration += 1;
    unawaited(workspaceStorage.clear());
    emit(const SessionState(status: SessionStatus.sessionExpired));
    scheduleMicrotask(() {
      if (!isClosed && state.status == SessionStatus.sessionExpired) {
        emit(const SessionState.expired());
      }
    });
  }

  @override
  Future<void> close() async {
    await authSubscription.cancel();
    return super.close();
  }
}
