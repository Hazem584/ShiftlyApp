import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/session_coordinator_cubit.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/features/auth/domain/entities/authentication_exception.dart';

Future<bool> performResendVerificationEmail(
  SessionCoordinatorCubit cubit,
) async {
  final email = cubit.state.verificationEmail;
  if (cubit.state.status != SessionStatus.emailVerificationRequired ||
      cubit.state.resendingVerification ||
      email == null) {
    return false;
  }
  final generation = cubit.authenticationGeneration;
  cubit.updateState(
    SessionState(
      status: SessionStatus.emailVerificationRequired,
      verificationEmail: email,
      resendingVerification: true,
    ),
  );
  try {
    await cubit.authentication.resendSignUpVerification(email: email);
    if (!cubit.authenticationIsCurrent(generation)) return false;
    cubit.updateState(
      SessionState(
        status: SessionStatus.emailVerificationRequired,
        verificationEmail: email,
      ),
    );
    return true;
  } on AuthenticationException catch (error) {
    if (!cubit.authenticationIsCurrent(generation)) return false;
    cubit.updateState(
      SessionState(
        status: SessionStatus.emailVerificationRequired,
        verificationEmail: email,
        failure: error.failure,
      ),
    );
    return false;
  } catch (_) {
    if (!cubit.authenticationIsCurrent(generation)) return false;
    cubit.updateState(
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
