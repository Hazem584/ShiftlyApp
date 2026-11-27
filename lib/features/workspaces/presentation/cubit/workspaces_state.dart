import 'package:equatable/equatable.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_repository.dart';

class WorkspacesState extends Equatable {
  const WorkspacesState({
    this.loading = true,
    this.workspaces = const [],
    this.invitations = const [],
    this.leaving = false,
    this.creating = false,
    this.accepting = false,
    this.declining = false,
    this.respondingInvitationId,
    this.failure,
  });
  final bool leaving, loading, creating, accepting, declining;
  final List<WorkspaceRecord> workspaces;
  final List<WorkspaceInvitation> invitations;
  final String? respondingInvitationId;
  bool get busy => creating || accepting || declining || leaving;
  final Failure? failure;

  WorkspacesState copyWith({
    bool? loading,
    List<WorkspaceRecord>? workspaces,
    List<WorkspaceInvitation>? invitations,
    bool? leaving,
    bool? creating,
    bool? accepting,
    bool? declining,
    String? respondingInvitationId,
    bool clearResponding = false,
    Failure? failure,
    bool clearFailure = false,
  }) => WorkspacesState(
    leaving: leaving ?? this.leaving,
    loading: loading ?? this.loading,
    workspaces: workspaces ?? this.workspaces,
    invitations: invitations ?? this.invitations,
    creating: creating ?? this.creating,
    accepting: accepting ?? this.accepting,
    declining: declining ?? this.declining,
    respondingInvitationId: clearResponding
        ? null
        : respondingInvitationId ?? this.respondingInvitationId,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    loading,
    leaving,
    workspaces,
    invitations,
    creating,
    accepting,
    declining,
    respondingInvitationId,
    failure,
  ];
}
