import 'package:equatable/equatable.dart';
import 'package:shiftly/features/workspaces/data/workspace_repository.dart';

enum InvitationStatus { pending, accepted, revoked, expired, unknown }

class WorkspaceInvitation extends Equatable {
  const WorkspaceInvitation({
    required this.id,
    required this.workspaceId,
    required this.status,
    this.email,
    this.jobTitle,
    this.role = WorkspaceAccessRole.employee,
    this.expiresAt,
    this.acceptedAt,
    this.revokedAt,
    this.createdAt,
    this.updatedAt,
    this.workspace,
    this.inviteToken,
  });

  final String id;
  final String workspaceId;
  final String? email;
  final String? jobTitle;
  final WorkspaceAccessRole role;
  final InvitationStatus status;
  final DateTime? expiresAt;
  final DateTime? acceptedAt;
  final DateTime? revokedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final WorkspaceRecord? workspace;
  final String? inviteToken;

  @override
  List<Object?> get props => [
    id,
    workspaceId,
    email,
    jobTitle,
    role,
    status,
    expiresAt,
    acceptedAt,
    revokedAt,
    createdAt,
    updatedAt,
    workspace,
    inviteToken,
  ];
}

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
