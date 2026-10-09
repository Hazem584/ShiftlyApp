import 'package:shiftly/features/invitations/domain/entities/invitation_models.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_repository.dart';

export 'package:shiftly/features/invitations/domain/entities/invitation_models.dart';

abstract interface class InvitationRepository {
  Future<WorkspaceInvitation> createInvitation({
    required String workspaceId,
    required String email,
    String? jobTitle,
  });
  Future<List<WorkspaceInvitation>> listWorkspaceInvitations({
    required String workspaceId,
    InvitationStatus? status,
  });
  Future<List<WorkspaceInvitation>> listMyInvitations();
  Future<WorkspaceRecord> acceptInvitation(String inviteToken);
}
