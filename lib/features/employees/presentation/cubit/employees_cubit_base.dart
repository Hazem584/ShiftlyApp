import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_state.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';

abstract class EmployeesCubitBase extends Cubit<EmployeesState> {
  EmployeesCubitBase(
    this.repository, {
    this.invitations,
    this.onDashboardChanged,
  }) : super(const EmployeesLoading());

  final EmployeeRepository repository;
  final InvitationRepository? invitations;
  final void Function()? onDashboardChanged;
  EmployeeSessionScope? currentScope;
  var generation = 0;
  var requestId = 0;
  var sessionBound = false;

  Future<List<WorkspaceInvitation>> loadPending(String workspaceId) async {
    final invitationRepository = invitations;
    if (invitationRepository == null) return const [];
    final values = await invitationRepository.listWorkspaceInvitations(
      workspaceId: workspaceId,
      status: InvitationStatus.pending,
    );
    return values
        .where((item) => item.status == InvitationStatus.pending)
        .toList(growable: false);
  }

  Failure toFailure(Object error, String fallback) =>
      error is ApiException ? error.toFailure() : Failure(message: fallback);

  bool isCurrent(EmployeeSessionScope? scope, int gen, int reqId) =>
      !isClosed &&
      currentScope == scope &&
      generation == gen &&
      requestId == reqId;

  bool isScopeCurrent(EmployeeSessionScope? scope, int gen) =>
      !isClosed && currentScope == scope && generation == gen;
}
