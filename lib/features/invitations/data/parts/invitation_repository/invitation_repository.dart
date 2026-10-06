part of '../../invitation_repository.dart';

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
