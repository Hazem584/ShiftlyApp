import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';

class AttendanceReportsState {
  const AttendanceReportsState({
    this.range,
    this.period = ReportPeriod.monthly,
    this.report,
    this.employeeId,
    this.loading = false,
    this.failure,
  });
  final ReportRange? range;
  final ReportPeriod period;
  final AttendanceReport? report;
  final String? employeeId;
  final bool loading;
  final Failure? failure;
}

class AttendanceReportsCubit extends Cubit<AttendanceReportsState> {
  AttendanceReportsCubit(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const AttendanceReportsState());
  final AttendanceReportRepository _repository;
  final DateTime Function() _now;
  FeatureSessionScope? _scope;
  var _request = 0;

  void bindSession(FeatureSessionScope? scope) {
    final authorized = scope?.isManager == true ? scope : null;
    if (_scope == authorized) return;
    _scope = authorized;
    _request++;
    emit(const AttendanceReportsState());
  }

  Future<void> open() => state.range == null ? load() : Future.value();

  Future<void> load({ReportRange? range, ReportPeriod? period}) async {
    final scope = _scope;
    if (scope == null || isClosed) return;
    final request = ++_request;
    final chosenPeriod = period ?? state.period;
    final chosenRange =
        range ??
        state.range ??
        ReportRange.forPeriod(
          chosenPeriod,
          WorkspaceTime.inWorkspace(_now(), scope.timezone),
        );
    final employeeId = state.employeeId;
    emit(
      AttendanceReportsState(
        range: chosenRange,
        period: chosenPeriod,
        employeeId: employeeId,
        loading: true,
      ),
    );
    bool current() => !isClosed && _scope == scope && _request == request;
    try {
      final report = await _repository.load(
        workspaceId: scope.workspaceId,
        workspaceName: scope.workspaceName,
        timezone: scope.timezone,
        range: chosenRange,
        isCurrent: current,
      );
      if (!current()) return;
      if (report.workspaceId != scope.workspaceId ||
          report.timezone != scope.timezone ||
          report.range.startKey != chosenRange.startKey ||
          report.range.endKey != chosenRange.endKey) {
        throw const FormatException('Invalid report scope');
      }
      emit(
        AttendanceReportsState(
          range: chosenRange,
          period: chosenPeriod,
          report: report,
          employeeId: report.employees.any((e) => e.id == employeeId)
              ? employeeId
              : null,
        ),
      );
    } catch (error) {
      if (!current()) return;
      emit(
        AttendanceReportsState(
          range: chosenRange,
          period: chosenPeriod,
          employeeId: employeeId,
          failure: error is ApiException
              ? error.toFailure()
              : const Failure(message: 'Unable to load attendance report.'),
        ),
      );
    }
  }

  Future<void> selectPeriod(ReportPeriod period) async {
    final scope = _scope;
    if (scope == null || period == ReportPeriod.custom) return;
    await load(
      period: period,
      range: ReportRange.forPeriod(
        period,
        WorkspaceTime.inWorkspace(_now(), scope.timezone),
      ),
    );
  }

  Future<void> move(int direction) async {
    final range = state.range;
    if (range != null) await load(range: range.move(state.period, direction));
  }

  void selectEmployee(String? id) {
    final report = state.report;
    if (state.loading ||
        report == null ||
        (id != null && !report.employees.any((e) => e.id == id))) {
      return;
    }
    emit(
      AttendanceReportsState(
        range: state.range,
        period: state.period,
        report: report,
        employeeId: id,
      ),
    );
  }

  void invalidate() {
    if (_scope != null && state.range != null) {
      _request++;
      emit(
        AttendanceReportsState(
          range: state.range,
          period: state.period,
          employeeId: state.employeeId,
          failure: const Failure(
            message: 'Attendance changed. Refresh the report.',
          ),
        ),
      );
    }
  }

  bool canExport(AttendanceReport report) =>
      !isClosed &&
      !state.loading &&
      _scope?.isManager == true &&
      identical(state.report, report);
}
