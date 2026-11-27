import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/session_coordinator_cubit.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/features/auth/domain/entities/authentication_exception.dart';

Future<void> performSignUp(
  SessionCoordinatorCubit cubit, {
  required String email,
  required String password,
  required Future<void> Function() resolveUser,
}) async {
  if (cubit.state.status == SessionStatus.registering) return;
  final normalizedEmail = email.trim().toLowerCase();
  final generation = ++cubit.authenticationGeneration;
  cubit.updateState(const SessionState(status: SessionStatus.registering));
  try {
    final result = await cubit.authentication.signUp(
      email: normalizedEmail,
      password: password,
    );
    if (!cubit.authenticationIsCurrent(generation)) return;
    if (result.session != null) {
      await resolveUser();
      return;
    }
    if (result.emailVerificationRequired) {
      cubit.updateState(
        SessionState(
          status: SessionStatus.emailVerificationRequired,
          verificationEmail: normalizedEmail,
        ),
      );
      return;
    }
    cubit.updateState(
      const SessionState(
        status: SessionStatus.failure,
        failure: Failure(
          message:
              'Account creation could not be completed. Please try again.',
        ),
      ),
    );
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
          message:
              'Unable to create your account. Check your connection and retry.',
          kind: FailureKind.network,
        ),
      ),
    );
  }
}
