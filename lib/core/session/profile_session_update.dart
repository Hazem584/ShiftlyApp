import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/core/session/session_state.dart';

SessionState? sessionWithUpdatedProfile(
  SessionState state,
  ManagerProfile profile,
) {
  final user = state.currentUser;
  if (user == null || profile.id != user.id) return null;
  return SessionState(
    status: state.status,
    currentUser: user.copyWithProfile(
      email: profile.email,
      fullName: profile.fullName,
      phone: profile.phone,
      avatarUrl: profile.avatarUrl,
      updatedAt: profile.updatedAt,
    ),
    activeMembership: state.activeMembership,
    failure: state.failure,
  );
}
