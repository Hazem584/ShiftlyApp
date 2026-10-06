part of '../../employees_cubit.dart';

final class EmployeeSessionScope extends Equatable {
  const EmployeeSessionScope({
    required this.userId,
    required this.workspaceId,
    required this.role,
  });
  final String userId;
  final String workspaceId;
  final WorkspaceRole role;
  bool get canManage => role == WorkspaceRole.manager;
  @override
  List<Object?> get props => [userId, workspaceId, role];
}
