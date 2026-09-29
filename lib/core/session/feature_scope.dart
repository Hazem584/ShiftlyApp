import 'package:equatable/equatable.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';

class FeatureSessionScope extends Equatable {
  const FeatureSessionScope({
    required this.userId,
    required this.workspaceId,
    required this.membershipId,
    required this.timezone,
    required this.role,
    this.workspaceName = '',
  });

  final String userId;
  final String workspaceId;
  final String membershipId;
  final String timezone;
  final WorkspaceRole role;
  final String workspaceName;

  bool get isManager => role == WorkspaceRole.manager;
  bool get isEmployee => role == WorkspaceRole.employee;

  @override
  List<Object?> get props => [
    userId,
    workspaceId,
    membershipId,
    timezone,
    role,
    workspaceName,
  ];
}
