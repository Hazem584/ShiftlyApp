import 'dart:async';

import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit_base.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_load_mixin.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_mutation_mixin.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_state.dart';

export 'package:shiftly/features/employees/presentation/cubit/employees_state.dart';

class EmployeesCubit extends EmployeesCubitBase
    with EmployeesLoadMixin, EmployeesMutationMixin {
  EmployeesCubit(
    super.repository, {
    super.invitations,
    super.onDashboardChanged,
  });

  void bindSession(EmployeeSessionScope? scope) {
    sessionBound = true;
    if (currentScope == scope) return;
    currentScope = scope;
    generation += 1;
    requestId += 1;
    emit(const EmployeesLoading());
    if (scope?.canManage == true) unawaited(load());
  }

  Future<void> loadMore() async {
    final current = state, scope = currentScope;
    if (current is! EmployeesLoaded ||
        current.loadingMore ||
        !current.hasMore ||
        (sessionBound && scope == null)) {
      return;
    }
    final gen = generation, reqId = ++requestId;
    emit(current.copyWith(loadingMore: true, clearFailure: true));
    try {
      final page = await repository.listEmployees(
        workspaceId: scope?.workspaceId ?? 'preview',
        search: current.query,
        status: current.status,
        page: current.page + 1,
      );
      if (!isCurrent(scope, gen, reqId)) return;
      final ids = current.employees.map((item) => item.id).toSet();
      final merged = [
        ...current.employees,
        ...page.data.where((item) => ids.add(item.id)),
      ];
      emit(
        current.copyWith(
          employees: merged,
          page: page.page,
          total: page.total,
          totalPages: page.totalPages,
          loadingMore: false,
        ),
      );
    } catch (error) {
      if (!isCurrent(scope, gen, reqId)) return;
      final err = toFailure(error, 'Could not load more employees.');
      emit(current.copyWith(loadingMore: false, failure: err));
    }
  }

  Future<void> add(Employee employee) async {
    await repository.addEmployee(employee);
    await load();
    onDashboardChanged?.call();
  }
}
