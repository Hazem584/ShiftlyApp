import 'package:equatable/equatable.dart';
import 'package:shiftly/features/workspaces/domain/entities/workspace_access_role.dart';
import 'package:shiftly/features/workspaces/domain/entities/workspace_access_status.dart';

class WorkspaceRecord extends Equatable {
  const WorkspaceRecord({
    required this.id,
    required this.name,
    required this.code,
    required this.timezone,
    required this.role,
    required this.status,
  });

  final String id;
  final String name;
  final String code;
  final String timezone;
  final WorkspaceAccessRole role;
  final WorkspaceAccessStatus status;

  bool get grantsAccess =>
      status == WorkspaceAccessStatus.active &&
      role != WorkspaceAccessRole.unknown;

  @override
  List<Object?> get props => [id, name, code, timezone, role, status];
}
