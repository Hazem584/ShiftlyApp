import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit_base.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_state.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';

mixin EmployeesMutationMixin on EmployeesCubitBase {
  Future<WorkspaceInvitation?> invite({
    required String email,
    String? jobTitle,
  }) async {
    final current = state, scope = currentScope, repo = invitations;
    if (current is! EmployeesLoaded ||
        current.inviting ||
        repo == null ||
        (sessionBound && scope == null)) {
      return null;
    }
    final gen = generation, wsId = scope?.workspaceId ?? 'preview';
    emit(current.copyWith(inviting: true, clearFailure: true));
    try {
      final inv = await repo.createInvitation(
        workspaceId: wsId,
        email: email,
        jobTitle: jobTitle,
      );
      if (!isScopeCurrent(scope, gen)) return null;
      final pending = await loadPending(wsId);
      if (!isScopeCurrent(scope, gen)) return null;
      emit(current.copyWith(inviting: false, pendingInvitations: pending));
      return inv;
    } catch (error) {
      if (!isScopeCurrent(scope, gen)) return null;
      final err = toFailure(error, 'Could not create invitation.');
      emit(current.copyWith(inviting: false, failure: err));
      rethrow;
    }
  }

  Future<EmployeeOperationResult> setStatus(
    String membershipId,
    EmployeeStatusFilter status,
  ) async {
    final current = state, scope = currentScope;
    if (current is! EmployeesLoaded || (sessionBound && scope == null)) {
      return EmployeeOperationResult.failure;
    }
    if (current.mutatingMembershipId != null) {
      return EmployeeOperationResult.busy;
    }
    final gen = generation;
    emit(current.copyWith(mutatingMembershipId: membershipId));
    try {
      final emp = await repository.setEmployeeStatus(
        workspaceId: scope?.workspaceId ?? 'preview',
        membershipId: membershipId,
        status: status,
      );
      if (!isScopeCurrent(scope, gen)) return EmployeeOperationResult.stale;
      emit(_applyUpdatedEmployee(current, emp));
      onDashboardChanged?.call();
      return EmployeeOperationResult.success;
    } catch (error) {
      if (!isScopeCurrent(scope, gen)) return EmployeeOperationResult.stale;
      final err = toFailure(error, 'Could not update employee status.');
      emit(current.copyWith(clearMutatingMembership: true, failure: err));
      return EmployeeOperationResult.failure;
    }
  }

  EmployeesLoaded _applyUpdatedEmployee(EmployeesLoaded c, Employee emp) {
    final wasListed = c.employees.any((item) => item.id == emp.id);
    final matches = switch (c.status) {
      EmployeeStatusFilter.active =>
        emp.employmentStatus == EmploymentStatus.active,
      EmployeeStatusFilter.suspended =>
        emp.employmentStatus == EmploymentStatus.suspended,
      null => true,
    };
    final list = matches
        ? c.employees
              .map((i) => i.id == emp.id ? emp : i)
              .toList(growable: false)
        : c.employees.where((i) => i.id != emp.id).toList(growable: false);
    final total = wasListed && !matches && c.total > 0 ? c.total - 1 : c.total;
    return c.copyWith(
      employees: list,
      total: total,
      clearMutatingMembership: true,
    );
  }
}
