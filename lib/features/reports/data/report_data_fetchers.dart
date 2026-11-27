import 'package:shiftly/core/models/employee_role.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';
import 'package:shiftly/features/reports/data/report_page_validator.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';

export 'package:shiftly/features/reports/data/report_page_validator.dart';

Future<List<AttendanceRecordApi>> fetchAllReportAttendance(
  AttendanceRepository attendance,
  String workspaceId,
  ({DateTime from, DateTime to}) bounds,
  bool Function() isCurrent,
) async {
  final records = <AttendanceRecordApi>[];
  final ids = <String>{};
  int? total;
  for (var page = 1; page <= ReportPageValidator.maxPages; page++) {
    ReportPageValidator.checkCurrent(isCurrent);
    final res = await attendance.listWorkspaceAttendance(
      workspaceId,
      AttendanceQuery(
        page: page,
        limit: ReportPageValidator.limit,
        from: bounds.from,
        to: bounds.to,
      ),
    );
    ReportPageValidator.checkCurrent(isCurrent);
    final p = res.pagination;
    ReportPageValidator.checkPage(
      page,
      p.page,
      p.limit,
      p.total,
      p.totalPages,
      res.data.length,
      total,
    );
    total = p.total;
    for (final r in res.data) {
      if (!ids.add(r.id) ||
          r.workspaceId != workspaceId ||
          r.employee.membershipId != r.employeeMembershipId ||
          r.clockInAt.isBefore(bounds.from) ||
          r.clockInAt.isAfter(bounds.to)) {
        throw ReportPageValidator.changed();
      }
      records.add(r);
    }
    if (page >= p.totalPages) break;
  }
  if (records.length != total) throw ReportPageValidator.changed();
  return records;
}

Future<List<ReportEmployee>> fetchAllReportEmployees(
  EmployeeRepository repo,
  String workspaceId,
  bool Function() isCurrent,
) async {
  final employees = <String, ReportEmployee>{};
  final ids = <String>{};
  int? total;
  for (var page = 1; page <= ReportPageValidator.maxPages; page++) {
    ReportPageValidator.checkCurrent(isCurrent);
    final res = await repo.listEmployees(
      workspaceId: workspaceId,
      page: page,
      limit: ReportPageValidator.limit,
    );
    ReportPageValidator.checkCurrent(isCurrent);
    ReportPageValidator.checkPage(
      page,
      res.page,
      res.limit,
      res.total,
      res.totalPages,
      res.data.length,
      total,
    );
    total = res.total;
    for (final emp in res.data) {
      if (!ids.add(emp.id)) throw ReportPageValidator.changed();
      if (emp.role == EmployeeRole.employee) {
        employees[emp.id] = ReportEmployee(
          emp.id,
          emp.displayName,
          monthlySalary: emp.monthlySalary,
          hourlyRate: emp.hourlyRate,
        );
      }
    }
    if (page >= res.totalPages) break;
  }
  if (ids.length != total) throw ReportPageValidator.changed();
  return employees.values.toList();
}
