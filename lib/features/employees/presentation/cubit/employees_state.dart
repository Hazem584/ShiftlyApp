import 'package:equatable/equatable.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';

export 'employees_base_state.dart';

sealed class EmployeesState extends Equatable {
  const EmployeesState();
  @override
  List<Object?> get props => [];
}

final class EmployeesLoading extends EmployeesState {
  const EmployeesLoading();
}

final class EmployeesError extends EmployeesState {
  const EmployeesError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

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
  final int page, total, totalPages;
  final bool loadingMore, refreshing, inviting;
  final String? mutatingMembershipId;
  final List<WorkspaceInvitation> pendingInvitations;
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
