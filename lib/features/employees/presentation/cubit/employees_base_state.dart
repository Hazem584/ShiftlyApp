import 'package:equatable/equatable.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';

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

enum EmployeeOperationResult { success, failure, busy, stale }
