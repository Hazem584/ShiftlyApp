import 'package:equatable/equatable.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';

class FeatureSessionScope extends Equatable {
  const FeatureSessionScope({
    required this.userId,
    required this.workspaceId,
    required this.membershipId,
    required this.timezone,
    required this.role,
    this.workspaceName = '',
    this.membershipStatus = MembershipStatus.active,
    this.generation = 0,
  });

  final String userId;
  final String workspaceId;
  final String membershipId;
  final String timezone;
  final WorkspaceRole role;
  final String workspaceName;
  final MembershipStatus membershipStatus;
  final int generation;

  bool get isManager =>
      role == WorkspaceRole.manager &&
      membershipStatus == MembershipStatus.active;
  bool get isEmployee =>
      role == WorkspaceRole.employee &&
      membershipStatus == MembershipStatus.active;

  @override
  List<Object?> get props => [
    userId,
    workspaceId,
    membershipId,
    timezone,
    role,
    workspaceName,
    membershipStatus,
    generation,
  ];
}
