import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/models/employee_role.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';

class ApiAttendanceReportRepository implements AttendanceReportRepository {
  ApiAttendanceReportRepository(
    this._attendance,
    this._employees, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;
  final AttendanceRepository _attendance;
  final EmployeeRepository _employees;
  final DateTime Function() _now;
  static const _limit = 100;
  static const _maxPages = 100;

  @override
  Future<AttendanceReport> load({
    required String workspaceId,
    required String workspaceName,
    required String timezone,
    required ReportRange range,
    required bool Function() isCurrent,
  }) async {
    final bounds = range.utcBounds(timezone);
    final records = <AttendanceRecordApi>[];
    final ids = <String>{};
    int? total;
    for (var page = 1; page <= _maxPages; page++) {
      _checkCurrent(isCurrent);
      final result = await _attendance.listWorkspaceAttendance(
        workspaceId,
        AttendanceQuery(
          page: page,
          limit: _limit,
          from: bounds.from,
          to: bounds.to,
        ),
      );
      _checkCurrent(isCurrent);
      final p = result.pagination;
      _checkPage(
        page,
        p.page,
        p.limit,
        p.total,
        p.totalPages,
        result.data.length,
        total,
      );
      total = p.total;
      for (final r in result.data) {
        if (!ids.add(r.id) ||
            r.workspaceId != workspaceId ||
            r.employee.membershipId != r.employeeMembershipId ||
            r.clockInAt.isBefore(bounds.from) ||
            r.clockInAt.isAfter(bounds.to)) {
          throw _changed();
        }
        records.add(r);
      }
      if (page >= p.totalPages) break;
    }
    if (records.length != total) throw _changed();
    final employees = <String, ReportEmployee>{};
    final employeeIds = <String>{};
    total = null;
    for (var page = 1; page <= _maxPages; page++) {
      _checkCurrent(isCurrent);
      final result = await _employees.listEmployees(
        workspaceId: workspaceId,
        page: page,
        limit: _limit,
      );
      _checkCurrent(isCurrent);
      _checkPage(
        page,
        result.page,
        result.limit,
        result.total,
        result.totalPages,
        result.data.length,
        total,
      );
      total = result.total;
      for (final employee in result.data) {
        if (!employeeIds.add(employee.id)) throw _changed();
        if (employee.role == EmployeeRole.employee) {
          employees[employee.id] = ReportEmployee(
            employee.id,
            employee.displayName,
          );
        }
      }
      if (page >= result.totalPages) break;
    }
    if (employeeIds.length != total) throw _changed();
    // Keep historical attendance even when a membership no longer appears in the roster.
    for (final r in records) {
      employees.putIfAbsent(
        r.employeeMembershipId,
        () => ReportEmployee(r.employeeMembershipId, r.employee.displayName),
      );
    }
    final sorted = employees.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    records.sort((a, b) => a.clockInAt.compareTo(b.clockInAt));
    return AttendanceReport(
      workspaceId: workspaceId,
      workspaceName: workspaceName,
      timezone: timezone,
      range: range,
      generatedAt: _now().toUtc(),
      employees: sorted,
      records: records,
    );
  }

  void _checkPage(
    int requested,
    int page,
    int limit,
    int total,
    int pages,
    int count,
    int? previousTotal,
  ) {
    if (total > _limit * _maxPages) {
      throw const ApiException(
        message: 'This report is too large. Choose a shorter period.',
      );
    }
    if (page != requested ||
        limit != _limit ||
        total < 0 ||
        pages != (total / _limit).ceil() ||
        count > _limit ||
        (requested < pages && count != _limit) ||
        (previousTotal != null && previousTotal != total)) {
      throw _changed();
    }
  }

  void _checkCurrent(bool Function() isCurrent) {
    if (!isCurrent()) {
      throw const ApiException(message: 'Report request cancelled.');
    }
  }

  ApiException _changed() => const ApiException(
    message: 'Attendance changed while loading. Refresh the report.',
  );
}
