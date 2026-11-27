import 'package:flutter/material.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';

export 'package:shiftly/features/reports/presentation/attendance_details_source.dart';

class AttendanceSummarySource extends DataTableSource {
  AttendanceSummarySource(this.rows);
  final List<ReportEmployeeRow> rows;

  @override
  DataRow? getRow(int index) {
    if (index >= rows.length) return null;
    final r = rows[index], m = r.metrics;
    return DataRow.byIndex(
      index: index,
      cells: [
        for (final value in [
          r.employee.name,
          m.attendanceDays,
          m.approved,
          m.pending,
          m.rejected,
          m.open,
          m.late,
          m.lateMinutes,
          (m.workMinutes / 60).toStringAsFixed(2),
          (m.extraMinutes / 60).toStringAsFixed(2),
          (m.excessMinutes / 60).toStringAsFixed(2),
        ])
          DataCell(Text('$value')),
      ],
    );
  }

  @override
  int get rowCount => rows.length;
  @override
  bool get isRowCountApproximate => false;
  @override
  int get selectedRowCount => 0;
}
