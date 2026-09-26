import 'package:equatable/equatable.dart';

enum WorkspaceAccessRole { manager, employee, unknown }

enum WorkspaceAccessStatus { active, invited, suspended, unknown }

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

abstract interface class WorkspaceRepository {
  Future<WorkspaceRecord> createWorkspace({
    required String name,
    String? timezone,
  });
  Future<List<WorkspaceRecord>> listWorkspaces();
  Future<WorkspaceRecord> getWorkspace(String workspaceId);
}
