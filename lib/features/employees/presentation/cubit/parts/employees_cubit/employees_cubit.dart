part of '../../employees_cubit.dart';

class EmployeesCubit extends Cubit<EmployeesState> {
  EmployeesCubit(this._repository, {this.invitations, this.onDashboardChanged})
    : super(const EmployeesLoading());

  final EmployeeRepository _repository;
  final InvitationRepository? invitations;
  final void Function()? onDashboardChanged;
  EmployeeSessionScope? _scope;
  var _generation = 0;
  var _requestId = 0;
  var _sessionBound = false;

  void bindSession(EmployeeSessionScope? scope) {
    _sessionBound = true;
    if (_scope == scope) return;
    _scope = scope;
    _generation += 1;
    _requestId += 1;
    emit(const EmployeesLoading());
    if (scope?.canManage == true) unawaited(load());
  }

  Future<void> load({
    String query = '',
    EmployeeStatusFilter? status,
    bool refresh = false,
  }) async {
    final scope = _scope;
    if (_sessionBound && (scope == null || !scope.canManage)) return;
    final generation = _generation;
    final requestId = ++_requestId;
    final current = state;
    if (refresh && current is EmployeesLoaded) {
      emit(current.copyWith(refreshing: true, clearFailure: true));
    } else {
      emit(const EmployeesLoading());
    }
    try {
      final page = await _repository.listEmployees(
        workspaceId: scope?.workspaceId ?? 'preview',
        search: query,
        status: status,
      );
      final pending = await _loadPending(scope?.workspaceId ?? 'preview');
      if (!_isCurrent(scope, generation, requestId)) return;
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
      if (!_isCurrent(scope, generation, requestId)) return;
      final failure = _failure(error, 'Unable to load employees.');
      if (refresh && current is EmployeesLoaded) {
        emit(current.copyWith(refreshing: false, failure: failure));
      } else {
        emit(EmployeesError(failure.message));
      }
    }
  }

  Future<void> loadMore() async {
    final current = state;
    final scope = _scope;
    if (current is! EmployeesLoaded ||
        current.loadingMore ||
        !current.hasMore ||
        (_sessionBound && scope == null)) {
      return;
    }
    final generation = _generation;
    final requestId = ++_requestId;
    emit(current.copyWith(loadingMore: true, clearFailure: true));
    try {
      final page = await _repository.listEmployees(
        workspaceId: scope?.workspaceId ?? 'preview',
        search: current.query,
        status: current.status,
        page: current.page + 1,
      );
      if (!_isCurrent(scope, generation, requestId)) return;
      final ids = current.employees.map((item) => item.id).toSet();
      emit(
        current.copyWith(
          employees: [
            ...current.employees,
            ...page.data.where((item) => ids.add(item.id)),
          ],
          page: page.page,
          total: page.total,
          totalPages: page.totalPages,
          loadingMore: false,
        ),
      );
    } catch (error) {
      if (!_isCurrent(scope, generation, requestId)) return;
      emit(
        current.copyWith(
          loadingMore: false,
          failure: _failure(error, 'Could not load more employees.'),
        ),
      );
    }
  }

  Future<WorkspaceInvitation?> invite({
    required String email,
    String? jobTitle,
  }) async {
    final current = state;
    final scope = _scope;
    final invitationRepository = invitations;
    if (current is! EmployeesLoaded ||
        current.inviting ||
        invitationRepository == null ||
        (_sessionBound && scope == null)) {
      return null;
    }
    final generation = _generation;
    emit(current.copyWith(inviting: true, clearFailure: true));
    try {
      final invitation = await invitationRepository.createInvitation(
        workspaceId: scope?.workspaceId ?? 'preview',
        email: email,
        jobTitle: jobTitle,
      );
      if (!_isScopeCurrent(scope, generation)) return null;
      final pending = await _loadPending(scope?.workspaceId ?? 'preview');
      if (!_isScopeCurrent(scope, generation)) return null;
      emit(current.copyWith(inviting: false, pendingInvitations: pending));
      return invitation;
    } catch (error) {
      if (!_isScopeCurrent(scope, generation)) return null;
      emit(
        current.copyWith(
          inviting: false,
          failure: _failure(error, 'Could not create invitation.'),
        ),
      );
      rethrow;
    }
  }

  Future<EmployeeOperationResult> setStatus(
    String membershipId,
    EmployeeStatusFilter status,
  ) async {
    final current = state;
    final scope = _scope;
    if (current is! EmployeesLoaded || (_sessionBound && scope == null)) {
      return EmployeeOperationResult.failure;
    }
    if (current.mutatingMembershipId != null) {
      return EmployeeOperationResult.busy;
    }
    final generation = _generation;
    emit(current.copyWith(mutatingMembershipId: membershipId));
    try {
      final employee = await _repository.setEmployeeStatus(
        workspaceId: scope?.workspaceId ?? 'preview',
        membershipId: membershipId,
        status: status,
      );
      if (!_isScopeCurrent(scope, generation)) {
        return EmployeeOperationResult.stale;
      }
      final wasListed = current.employees.any((item) => item.id == employee.id);
      final matchesFilter = switch (current.status) {
        EmployeeStatusFilter.active =>
          employee.employmentStatus == EmploymentStatus.active,
        EmployeeStatusFilter.suspended =>
          employee.employmentStatus == EmploymentStatus.suspended,
        null => true,
      };
      emit(
        current.copyWith(
          employees: matchesFilter
              ? current.employees
                    .map((item) => item.id == employee.id ? employee : item)
                    .toList(growable: false)
              : current.employees
                    .where((item) => item.id != employee.id)
                    .toList(growable: false),
          total: wasListed && !matchesFilter && current.total > 0
              ? current.total - 1
              : current.total,
          clearMutatingMembership: true,
        ),
      );
      onDashboardChanged?.call();
      return EmployeeOperationResult.success;
    } catch (error) {
      if (!_isScopeCurrent(scope, generation)) {
        return EmployeeOperationResult.stale;
      }
      emit(
        current.copyWith(
          clearMutatingMembership: true,
          failure: _failure(error, 'Could not update employee status.'),
        ),
      );
      return EmployeeOperationResult.failure;
    }
  }

  Future<void> add(Employee employee) async {
    await _repository.addEmployee(employee);
    await load();
    onDashboardChanged?.call();
  }

  Future<List<WorkspaceInvitation>> _loadPending(String workspaceId) async {
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

  Failure _failure(Object error, String fallback) =>
      error is ApiException ? error.toFailure() : Failure(message: fallback);
  bool _isCurrent(EmployeeSessionScope? scope, int generation, int requestId) =>
      !isClosed &&
      _scope == scope &&
      _generation == generation &&
      _requestId == requestId;
  bool _isScopeCurrent(EmployeeSessionScope? scope, int generation) =>
      !isClosed && _scope == scope && _generation == generation;
}
