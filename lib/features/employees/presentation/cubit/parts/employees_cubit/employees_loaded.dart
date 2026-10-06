part of '../../employees_cubit.dart';

final class EmployeesLoaded extends EmployeesState {
  const EmployeesLoaded({
    required this.employees,
    required this.query,
    this.status,
    this.page = 1,
    this.total = 0,
    this.totalPages = 0,
    this.loadingMore = false,
    this.refreshing = false,
    this.mutatingMembershipId,
    this.pendingInvitations = const [],
    this.inviting = false,
    this.failure,
  });
  final List<Employee> employees;
  final String query;
  final EmployeeStatusFilter? status;
  final int page;
  final int total;
  final int totalPages;
  final bool loadingMore;
  final bool refreshing;
  final String? mutatingMembershipId;
  final List<WorkspaceInvitation> pendingInvitations;
  final bool inviting;
  final Failure? failure;
  bool get hasMore => page < totalPages;

  EmployeesLoaded copyWith({
    List<Employee>? employees,
    String? query,
    EmployeeStatusFilter? status,
    bool clearStatus = false,
    int? page,
    int? total,
    int? totalPages,
    bool? loadingMore,
    bool? refreshing,
    String? mutatingMembershipId,
    bool clearMutatingMembership = false,
    List<WorkspaceInvitation>? pendingInvitations,
    bool? inviting,
    Failure? failure,
    bool clearFailure = false,
  }) => EmployeesLoaded(
    employees: employees ?? this.employees,
    query: query ?? this.query,
    status: clearStatus ? null : status ?? this.status,
    page: page ?? this.page,
    total: total ?? this.total,
    totalPages: totalPages ?? this.totalPages,
    loadingMore: loadingMore ?? this.loadingMore,
    refreshing: refreshing ?? this.refreshing,
    mutatingMembershipId: clearMutatingMembership
        ? null
        : mutatingMembershipId ?? this.mutatingMembershipId,
    pendingInvitations: pendingInvitations ?? this.pendingInvitations,
    inviting: inviting ?? this.inviting,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    employees,
    query,
    status,
    page,
    total,
    totalPages,
    loadingMore,
    refreshing,
    mutatingMembershipId,
    pendingInvitations,
    inviting,
    failure,
  ];
}
