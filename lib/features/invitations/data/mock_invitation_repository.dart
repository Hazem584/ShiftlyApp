import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_repository.dart';

class MockInvitationRepository implements InvitationRepository {
  final List<WorkspaceInvitation> _items = [];
  @override
  Future<WorkspaceRecord> acceptInvitation(String inviteToken) async =>
      const WorkspaceRecord(
        id: 'preview-workspace',
        name: 'Preview workspace',
        code: 'PREVIEW',
        timezone: 'Africa/Cairo',
        role: WorkspaceAccessRole.employee,
        status: WorkspaceAccessStatus.active,
      );
  @override
  Future<WorkspaceInvitation> createInvitation({
    required String workspaceId,
    required String email,
    String? jobTitle,
  }) async {
    final item = WorkspaceInvitation(
      id: 'invitation-${_items.length + 1}',
      workspaceId: workspaceId,
      email: email.trim().toLowerCase(),
      jobTitle: jobTitle?.trim(),
      status: InvitationStatus.pending,
      inviteToken: 'preview-token-${_items.length + 1}',
    );
    _items.add(item);
    return item;
  }

  @override
  Future<List<WorkspaceInvitation>> listMyInvitations() async => const [];
  @override
  Future<List<WorkspaceInvitation>> listWorkspaceInvitations({
    required String workspaceId,
    InvitationStatus? status,
  }) async => _items
      .where(
        (item) =>
            item.workspaceId == workspaceId &&
            (status == null || item.status == status),
      )
      .toList(growable: false);
}
