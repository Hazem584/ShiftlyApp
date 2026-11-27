import 'package:shiftly/features/attendance/domain/repositories/attendance_calendar_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';
import 'package:shiftly/features/reports/data/report_data_fetchers.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';

import 'report_payroll_days.dart';
import 'report_preparation.dart';

class ApiAttendanceReportRepository implements AttendanceReportRepository {
  ApiAttendanceReportRepository(
    this._attendance,
    this._employees, {
    DateTime Function()? now,
    this.calendar,
  }) : _now = now ?? DateTime.now;

  final AttendanceRepository _attendance;
  final EmployeeRepository _employees;
  final DateTime Function() _now;
  final AttendanceCalendarRepository? calendar;

  @override
  Future<AttendanceReport> load({
    required String workspaceId,
    required String workspaceName,
    required String timezone,
    required ReportRange range,
    required bool Function() isCurrent,
  }) async {
    final bounds = range.utcBounds(timezone);
    final records = await fetchAllReportAttendance(
      _attendance,
      workspaceId,
      bounds,
      isCurrent,
    );
    final employees = await fetchAllReportEmployees(
      _employees,
      workspaceId,
      isCurrent,
    );
    ReportPageValidator.checkCurrent(isCurrent);
    final calendar = this.calendar;
    final payrollDays =
        calendar != null && employees.any((e) => e.monthlySalary != null)
        ? await fetchReportPayrollDays(
            calendar,
            workspaceId,
            timezone,
            range,
            isCurrent,
          )
        : null;
    final report = await prepareAttendanceReport(
      ReportPreparation(
        workspaceId: workspaceId,
        workspaceName: workspaceName,
        timezone: timezone,
        range: range,
        generatedAt: _now().toUtc(),
        employees: employees,
        records: records,
        payrollDays: payrollDays,
      ),
    );
    ReportPageValidator.checkCurrent(isCurrent);
    return report;
  }
}
