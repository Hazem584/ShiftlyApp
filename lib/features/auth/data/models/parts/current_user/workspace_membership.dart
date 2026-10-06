part of '../../current_user.dart';

class WorkspaceMembership {
  const WorkspaceMembership({
    required this.id,
    required this.role,
    required this.status,
    required this.workspace,
    this.jobTitle,
    this.joinedAt,
  });

  final String id;
  final WorkspaceRole role;
  final MembershipStatus status;
  final String? jobTitle;
  final DateTime? joinedAt;
  final Workspace workspace;

  factory WorkspaceMembership.fromJson(Map<String, Object?> json) {
    final workspace = json['workspace'];
    if (workspace is! Map) throw const FormatException('Invalid workspace');
    return WorkspaceMembership(
      id: _requiredString(json, 'id'),
      role: WorkspaceRole.parse(json['role']),
      status: MembershipStatus.parse(json['status']),
      jobTitle: _optionalString(json['jobTitle']),
      joinedAt: _optionalDate(json['joinedAt']),
      workspace: Workspace.fromJson(Map<String, Object?>.from(workspace)),
    );
  }
}
