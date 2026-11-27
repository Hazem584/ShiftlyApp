import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';
import 'package:shiftly/features/reports/presentation/attendance_reports_state.dart';

export 'package:shiftly/features/reports/presentation/attendance_reports_state.dart';

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
    final request = ++_request, chosenPeriod = period ?? state.period;
    final chosenRange = range ?? state.range ?? _defaultRange(chosenPeriod);
    final empId = state.employeeId;
    emit(
      AttendanceReportsState(
        range: chosenRange,
        period: chosenPeriod,
        employeeId: empId,
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
      validateAttendanceReportScope(report, scope, chosenRange);
      emit(
        AttendanceReportsState(
          range: chosenRange,
          period: chosenPeriod,
          report: report,
          employeeId: report.employees.any((e) => e.id == empId) ? empId : null,
        ),
      );
    } catch (error) {
      if (!current()) return;
      emit(
        AttendanceReportsState(
          range: chosenRange,
          period: chosenPeriod,
          employeeId: empId,
          failure: error is ApiException
              ? error.toFailure()
              : const Failure(message: 'Unable to load attendance report.'),
        ),
      );
    }
  }

  ReportRange _defaultRange(ReportPeriod period) => ReportRange.forPeriod(
    period,
    WorkspaceTime.inWorkspace(_now(), _scope!.timezone),
  );

  Future<void> selectPeriod(ReportPeriod period) async {
    if (_scope == null || period == ReportPeriod.custom) return;
    await load(period: period, range: _defaultRange(period));
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
    emit(state.copyWithEmployee(id));
  }

  void invalidate() {
    if (_scope != null && state.range != null) {
      _request++;
      emit(state.invalidated());
    }
  }

  bool canExport(AttendanceReport report) =>
      !isClosed &&
      !state.loading &&
      _scope?.isManager == true &&
      identical(state.report, report);
}
