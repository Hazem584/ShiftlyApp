import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/session_coordinator_cubit.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/features/auth/domain/entities/authentication_exception.dart';

Future<void> performSignIn(
  SessionCoordinatorCubit cubit, {
  required String email,
  required String password,
  required Future<void> Function() resolveUser,
}) async {
  if (cubit.state.status == SessionStatus.authenticating) return;
  final generation = ++cubit.authenticationGeneration;
  cubit.updateState(const SessionState(status: SessionStatus.authenticating));
  try {
    final result = await cubit.authentication.signIn(
      email: email.trim().toLowerCase(),
      password: password,
    );
    if (!cubit.authenticationIsCurrent(generation)) return;
    if (result.emailVerificationRequired) {
      cubit.updateState(
        const SessionState(status: SessionStatus.emailVerificationRequired),
      );
      return;
    }
    if (result.session == null) {
      cubit.updateState(
        const SessionState(
          status: SessionStatus.failure,
          failure: Failure(message: 'Sign in did not create a session.'),
        ),
      );
      return;
    }
    await resolveUser();
  } on AuthenticationException catch (error) {
    if (!cubit.authenticationIsCurrent(generation)) return;
    cubit.updateState(
      SessionState(status: SessionStatus.failure, failure: error.failure),
    );
  } catch (_) {
    if (!cubit.authenticationIsCurrent(generation)) return;
    cubit.updateState(
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

Future<void> performBootstrapProfile(
  SessionCoordinatorCubit cubit, {
  String? fullName,
  String? phone,
  required Future<void> Function() resolveUser,
}) async {
  if (cubit.state.status == SessionStatus.loadingCurrentUser) return;
  final trimmedName = fullName?.trim();
  final trimmedPhone = phone?.trim();
  final generation = cubit.authenticationGeneration;
  cubit.updateState(
    const SessionState(status: SessionStatus.loadingCurrentUser),
  );
  try {
    await cubit.repository.bootstrapProfile(
      fullName: trimmedName,
      phone: trimmedPhone == null || trimmedPhone.isEmpty ? null : trimmedPhone,
    );
    if (!cubit.authenticationIsCurrent(generation) ||
        cubit.authentication.currentSession == null) {
      return;
    }
    await resolveUser();
  } on ApiException catch (error) {
    if (!cubit.authenticationIsCurrent(generation)) return;
    cubit.updateState(
      SessionState(status: SessionStatus.failure, failure: error.toFailure()),
    );
  }
}
