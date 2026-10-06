part of '../../workspaces_cubit.dart';

class WorkspacesState extends Equatable {
  const WorkspacesState({
    this.loading = true,
    this.workspaces = const [],
    this.invitations = const [],
    this.creating = false,
    this.accepting = false,
    this.failure,
  });
  final bool loading;
  final List<WorkspaceRecord> workspaces;
  final List<WorkspaceInvitation> invitations;
  final bool creating;
  final bool accepting;
  final Failure? failure;

  WorkspacesState copyWith({
    bool? loading,
    List<WorkspaceRecord>? workspaces,
    List<WorkspaceInvitation>? invitations,
    bool? creating,
    bool? accepting,
    Failure? failure,
    bool clearFailure = false,
  }) => WorkspacesState(
    loading: loading ?? this.loading,
    workspaces: workspaces ?? this.workspaces,
    invitations: invitations ?? this.invitations,
    creating: creating ?? this.creating,
    accepting: accepting ?? this.accepting,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    loading,
    workspaces,
    invitations,
    creating,
    accepting,
    failure,
  ];
}
