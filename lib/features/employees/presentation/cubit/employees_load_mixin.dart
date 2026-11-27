import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit_base.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_state.dart';

mixin EmployeesLoadMixin on EmployeesCubitBase {
  Future<void> load({
    String query = '',
    EmployeeStatusFilter? status,
    bool refresh = false,
  }) async {
    final scope = currentScope;
    if (sessionBound && (scope == null || !scope.canManage)) return;
    final gen = generation, reqId = ++requestId, current = state;
    if (refresh && current is EmployeesLoaded) {
      emit(current.copyWith(refreshing: true, clearFailure: true));
    } else {
      emit(const EmployeesLoading());
    }
    try {
      final wsId = scope?.workspaceId ?? 'preview';
      final page = await repository.listEmployees(
        workspaceId: wsId,
        search: query,
        status: status,
      );
      final pending = await loadPending(wsId);
      if (!isCurrent(scope, gen, reqId)) return;
      emit(
        EmployeesLoaded(
          employees: page.data,
          query: query,
          status: status,
          page: page.page,
          total: page.total,
          totalPages: page.totalPages,
          pendingInvitations: pending,
        ),
      );
    } catch (error) {
      if (!isCurrent(scope, gen, reqId)) return;
      final failure = toFailure(error, 'Unable to load employees.');
      if (refresh && current is EmployeesLoaded) {
        emit(current.copyWith(refreshing: false, failure: failure));
      } else {
        emit(EmployeesError(failure.message));
      }
    }
  }
}
