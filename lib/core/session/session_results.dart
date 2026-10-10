import 'package:shiftly/features/auth/domain/entities/current_user.dart';

class MembershipRefreshResult {
  const MembershipRefreshResult._({this.userId, this.workspaceId, this.role});

  const MembershipRefreshResult.failed() : this._();

  const MembershipRefreshResult.authorized({
    required String userId,
    required String workspaceId,
    required WorkspaceRole role,
  }) : this._(userId: userId, workspaceId: workspaceId, role: role);

  final String? userId;
  final String? workspaceId;
  final WorkspaceRole? role;

  bool authorizes({required String userId, required String workspaceId}) =>
      this.userId == userId &&
      this.workspaceId == workspaceId &&
      role != null &&
      role != WorkspaceRole.unknown;
}

enum WorkspaceSwitchResult { success, noAlternative, invalid, busy, failure }
