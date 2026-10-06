part of '../../dashboard_cubit.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repository) : super(const DashboardLoading());

  final DashboardRepository _repository;
  FeatureSessionScope? _scope;
  var _generation = 0;
  var _inFlight = false;
  var _queuedRefresh = false;

  FeatureSessionScope? get scope => _scope;

  void bindSession(FeatureSessionScope? scope) {
    final authorized = scope?.isManager == true || scope?.isEmployee == true
        ? scope
        : null;
    if (_scope == authorized) return;
    _scope = authorized;
    _generation += 1;
    _inFlight = false;
    _queuedRefresh = false;
    emit(const DashboardLoading());
    if (authorized != null) unawaited(load());
  }

  Future<void> load({bool refresh = false, bool background = false}) async {
    final scope = _scope;
    if (scope == null) return;
    if (_inFlight) {
      if (refresh || background) _queuedRefresh = true;
      return;
    }
    _inFlight = true;
    final generation = _generation;
    final previous = state;
    if (previous case DashboardLoaded()) {
      emit(
        background
            ? previous.copyWith(clearFailure: true)
            : previous.copyWith(refreshing: true, clearFailure: true),
      );
    } else {
      emit(const DashboardLoading());
    }
    try {
      final data = scope.isManager
          ? await _repository.getManagerDashboard(scope.workspaceId)
          : await _repository.getEmployeeDashboard(scope.workspaceId);
      if (!_current(scope, generation)) return;
      _validate(scope, data);
      emit(DashboardLoaded(data: data));
    } catch (error) {
      if (!_current(scope, generation)) return;
      final failure = _failure(error);
      if (previous case DashboardLoaded()) {
        emit(previous.copyWith(refreshing: false, failure: failure));
      } else {
        emit(DashboardError(failure));
      }
    } finally {
      if (_current(scope, generation)) {
        _inFlight = false;
        if (_queuedRefresh) {
          _queuedRefresh = false;
          unawaited(load(background: true));
        }
      }
    }
  }

  void invalidate() => unawaited(load(background: true));

  void _validate(FeatureSessionScope scope, DashboardData data) {
    if (data.timezone != scope.timezone) {
      throw const FormatException('Dashboard timezone does not match session');
    }
    if (data is ManagerDashboardData && !scope.isManager) {
      throw const FormatException('Manager dashboard returned to employee');
    }
    if (data is EmployeeDashboardData &&
        (!scope.isEmployee ||
            data.employee.membershipId != scope.membershipId)) {
      throw const FormatException('Employee dashboard identity mismatch');
    }
  }

  Failure _failure(Object error) => error is ApiException
      ? error.toFailure()
      : const Failure(message: 'We could not load your dashboard. Try again.');

  bool _current(FeatureSessionScope scope, int generation) =>
      !isClosed && _scope == scope && _generation == generation;
}
