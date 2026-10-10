import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';
import 'package:shiftly/features/reports/domain/report_export.dart';
import 'package:shiftly/features/shifts/domain/entities/attendance_review_status.dart';

class AttendanceReportExporter implements ReportExporter {
  @override
  Future<ReportExportFile> create(
    AttendanceReport report, {
    required ReportFileFormat format,
    required ReportLabels strings,
    String? employeeId,
  }) async {
    final rows = report.rowsFor(employeeId);
    final selected = employeeId == null
        ? strings.text('All employees')
        : rows.first.employee.name;
    final summaryHeaders = [
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
    ];
    List<Object> summary(ReportEmployeeRow row) {
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
      ];
    }

    final summaryRows = rows.map(summary).toList();
    final totals = ReportEmployeeRow(
      ReportEmployee('', strings.text('Total')),
      report.totalsFor(employeeId),
    );
    final detailHeaders = [
      'Employee',
      'Attendance ID',
      'Clock in',
      'Clock out',
      'Review status',
      'Shift kind',
      'Late minutes',
      'Recorded work minutes',
    ];
    final details = report
        .recordsFor(employeeId)
        .map(
          (r) => <Object>[
            r.employee.displayName,
            r.id,
            WorkspaceTime.dateTime(r.clockInAt, report.timezone),
            r.clockOutAt == null
                ? strings.text('Not recorded')
                : WorkspaceTime.dateTime(r.clockOutAt!, report.timezone),
            strings.text(switch (r.reviewStatus) {
              AttendanceReviewStatus.approved => 'Approved',
              AttendanceReviewStatus.pending => 'Pending',
              AttendanceReviewStatus.rejected => 'Rejected',
              AttendanceReviewStatus.unknown => 'Unknown',
            }),
            strings.text(
              r.occurrenceKind == 'EXTRA' ? 'Extra shift' : 'Regular shift',
            ),
            r.minutesLate,
            r.workedMinutes ?? '',
          ],
        )
        .toList();
    final notes = <String>[
      strings.text(
        'Hours include approved closed records only. Open, pending and rejected records do not add hours.',
      ),
      strings.text(
        'Extra shift hours are part of worked hours. Schedule excess is time beyond the scheduled duration of regular shifts; it is an estimate, not payroll approval.',
      ),
      strings.text(
        'Dates use clock-in time in the workspace timezone. Overnight work stays on the clock-in date. Breaks are not deducted.',
      ),
      strings.text(
        'Attendance days count distinct approved clock-in dates per employee. No attendance does not prove absence.',
      ),
      '${strings.text('Missing schedule')}: ${totals.metrics.missingSchedule}',
      '${strings.text('Missing work duration')}: ${totals.metrics.missingWorkMinutes}',
      '${strings.text('Unknown review status')}: ${totals.metrics.unknown}',
    ];
    final metadata = <List<Object>>[
      [strings.text('Workspace'), report.workspaceName],
      [strings.text('Period'), report.range.label],
      [strings.text('Employee filter'), selected],
      [strings.text('Timezone'), report.timezone],
      [
        strings.text('Generated at'),
        WorkspaceTime.dateTime(report.generatedAt, report.timezone),
      ],
      for (final note in notes) [note],
    ];
    final basename =
        'attendance_${report.range.startKey}_${report.range.endKey}'
        '${employeeId == null ? '' : '_employee'}';
    if (format == ReportFileFormat.excel) {
      final workbook = Excel.createExcel();
      workbook.rename('Sheet1', 'Summary');
      final summarySheet = workbook['Summary'];
      for (final row in metadata) {
        _append(summarySheet, row);
      }
      _append(summarySheet, []);
      _append(
        summarySheet,
        summaryHeaders.map(strings.text).toList(),
        header: true,
      );
      for (final row in summaryRows) {
        _append(summarySheet, row);
      }
      _append(summarySheet, summary(totals), header: true);
      summarySheet.setColumnWidth(0, 28);
      for (var column = 1; column < summaryHeaders.length; column++) {
        summarySheet.setColumnWidth(column, 22);
      }
      final detailSheet = workbook['Details'];
      _append(
        detailSheet,
        detailHeaders.map(strings.text).toList(),
        header: true,
      );
      for (var column = 0; column < detailHeaders.length; column++) {
        detailSheet.setColumnWidth(column, column == 1 ? 40 : 28);
      }
      for (final row in details) {
        _append(detailSheet, row);
      }
      final bytes = workbook.encode();
      if (bytes == null) {
        throw const FormatException('Unable to create workbook');
      }
      return ReportExportFile(
        Uint8List.fromList(bytes),
        '$basename.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    }

    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Cairo-Variable.ttf'),
    );
    final rtl = strings.isArabic;
    final direction = rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    pw.TextDirection contentDirection(String value) =>
        RegExp(r'[\u0600-\u06ff]').hasMatch(value)
        ? pw.TextDirection.rtl
        : pw.TextDirection.ltr;
    final document = pw.Document();
    List<List<String>> textRows(List<List<Object>> values) => values
        .map(
          (row) => row
              .map(
                (value) => value is double
                    ? value.toStringAsFixed(2)
                    : value.toString(),
              )
              .toList(),
        )
        .toList();
    pw.Widget table(List<String> headers, List<List<Object>> values) =>
        pw.TableHelper.fromTextArray(
          headers: rtl ? headers.reversed.toList() : headers,
          data: textRows(values)
              .map((row) => rtl ? row.reversed.toList() : row)
              .toList(),
          headerStyle: pw.TextStyle(font: font, fontSize: 8),
          headerDirection: direction,
          tableDirection: direction,
          cellBuilder: (_, value, _) => pw.Text(
            value.toString(),
            textDirection: contentDirection(value.toString()),
            style: pw.TextStyle(font: font, fontSize: 7),
          ),
          cellStyle: pw.TextStyle(font: font, fontSize: 7),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellPadding: const pw.EdgeInsets.all(4),
          cellAlignment: rtl
              ? pw.Alignment.centerRight
              : pw.Alignment.centerLeft,
        );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        maxPages: 1000,
        theme: pw.ThemeData.withFont(base: font, bold: font),
        textDirection: direction,
        footer: (context) => pw.Text(
          '${context.pageNumber} / ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8),
        ),
        build: (_) => [
          pw.Text(
            strings.text('Attendance reports'),
            style: const pw.TextStyle(fontSize: 18),
          ),
          pw.SizedBox(height: 8),
          for (final row in metadata)
            if (row.length == 1)
              pw.Text(
                row.single.toString(),
                style: const pw.TextStyle(fontSize: 9),
              )
            else
              pw.Row(
                children: [
                  pw.Text(
                    '${row.first}  ',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      row[1].toString(),
                      textDirection: contentDirection(row[1].toString()),
                      textAlign: rtl ? pw.TextAlign.right : pw.TextAlign.left,
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                ],
              ),
          pw.SizedBox(height: 12),
          table(summaryHeaders.map(strings.text).toList(), [
            ...summaryRows,
            summary(totals),
          ]),
          pw.NewPage(),
          pw.Text(
            strings.text('Attendance details'),
            style: const pw.TextStyle(fontSize: 16),
          ),
          pw.SizedBox(height: 8),
          if (details.isEmpty)
            pw.Text(strings.text('No attendance in this period.'))
          else
            table(detailHeaders.map(strings.text).toList(), details),
        ],
      ),
    );
    return ReportExportFile(
      await document.save(),
      '$basename.pdf',
      'application/pdf',
    );
  }

  void _append(Sheet sheet, List<Object> values, {bool header = false}) {
    final row = sheet.maxRows;
    sheet.appendRow(
      values.map<CellValue>((value) {
        if (value is int) return IntCellValue(value);
        if (value is double) return DoubleCellValue(value);
        // Names and other user content are text cells, never executable formulas.
        return TextCellValue(value.toString());
      }).toList(),
    );
    for (var column = 0; column < values.length; column++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row))
          .cellStyle = CellStyle(
        bold: header,
        textWrapping: TextWrapping.WrapText,
        numberFormat: values[column] is double
            ? NumFormat.standard_2
            : NumFormat.standard_0,
      );
    }
  }
}
