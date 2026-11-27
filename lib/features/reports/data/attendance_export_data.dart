import 'package:shiftly/features/reports/data/attendance_export_rows.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';
import 'package:shiftly/features/reports/domain/report_export.dart';

class ExportSheetData {
  ExportSheetData(ReportReportContext ctx)
    : strings = ctx.strings,
      basename =
          'attendance_${ctx.report.range.startKey}_${ctx.report.range.endKey}'
          '${ctx.employeeId == null ? '' : '_employee'}',
      rows = ctx.report.rowsFor(ctx.employeeId),
      totals = ReportEmployeeRow(
        ReportEmployee('', ctx.strings.text('Total')),
        ctx.report.totalsFor(ctx.employeeId),
      ),
      details = buildExportDetailRows(ctx.report, ctx.employeeId, ctx.strings),
      metadata = buildExportMetadataRows(
        ctx.report,
        ctx.employeeId,
        ctx.strings,
      );

  final ReportLabels strings;
  final String basename;
  final List<ReportEmployeeRow> rows;
  final ReportEmployeeRow totals;
  final List<List<Object>> details, metadata;

  static const summaryHeaders = [
    'Employee',
    'Attendance days',
    'Approved records',
    'Pending records',
    'Rejected records',
    'Open records',
    'Late records',
    'Late minutes',
    'Worked hours',
    'Extra shift hours',
    'Schedule excess hours',
    'Hourly rate',
    'Base pay',
    'Deductions',
    'Overtime pay',
    'Net payable',
  ];

  static const detailHeaders = [
    'Employee',
    'Attendance ID',
    'Clock in',
    'Clock out',
    'Review status',
    'Shift kind',
    'Late minutes',
    'Recorded work minutes',
    'Saved schedule',
    'Schedule exception reason',
  ];

  static List<Object> summaryRow(ReportEmployeeRow row) {
    final m = row.metrics;
    return [
      row.employee.name,
      m.attendanceDays,
      m.approved,
      m.pending,
      m.rejected,
      m.open,
      m.late,
      m.lateMinutes,
      m.workMinutes / 60,
      m.extraMinutes / 60,
      m.excessMinutes / 60,
      row.hourlyRate,
      row.basePay,
      row.deductions,
      row.overtimePay,
      row.netPay,
    ];
  }

  List<List<Object>> get summaryRows => rows.map(summaryRow).toList();
}

class ReportReportContext {
  const ReportReportContext(this.report, this.employeeId, this.strings);
  final AttendanceReport report;
  final String? employeeId;
  final ReportLabels strings;
}
