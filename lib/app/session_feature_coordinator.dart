import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';

class SessionFeatureCoordinator {
  SessionFeatureCoordinator(this._apply);

  final void Function(SessionState state, int generation) _apply;
  String? _identity;
  bool _initialized = false;
  int _generation = 0;

  int get generation => _generation;

  void bind(SessionState state) {
    final identity = _scopeIdentity(state);
    if (!_initialized || identity != _identity) {
      _initialized = true;
      _identity = identity;
      _generation++;
    }
    _apply(state, _generation);
  }

  void invalidate(SessionState state) {
    _generation++;
    _apply(state, _generation);
  }

  String? _scopeIdentity(SessionState state) {
    final user = state.currentUser;
    final membership = state.activeMembership;
    if (user == null || membership == null) return null;
    if (membership.status != MembershipStatus.active ||
        membership.role == WorkspaceRole.unknown) {
      return null;
    }
    return '${user.id}|${membership.workspace.id}|${membership.id}|'
        '${membership.role.name}|${membership.status.name}';
  }
}
