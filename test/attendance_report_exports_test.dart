import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/reports/data/attendance_report_exporter.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';
import 'package:shiftly/features/reports/domain/report_export.dart';

import 'support/report_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final exporter = AttendanceReportExporter();
  final english = ReportLabels(const AppLocalizations(Locale('en')).text);
  final arabic = ReportLabels(
    const AppLocalizations(Locale('ar')).text,
    isArabic: true,
  );

  test(
    'Excel is a real workbook with numeric totals and filtered detail rows',
    () async {
      final report = fixtureReport(
        records: [
          reportRecord(),
          reportRecord(
            id: 'other',
            employeeId: 'second',
            name: 'منى',
            work: 60,
          ),
        ],
      );
      final file = await exporter.create(
        report,
        format: ReportFileFormat.excel,
        strings: english,
        employeeId: 'second',
      );
      expect(file.name, endsWith('_employee.xlsx'));
      final workbook = Excel.decodeBytes(file.bytes);
      expect(workbook.tables.keys, ['Summary', 'Details']);
      final details = workbook.tables['Details']!.rows;
      expect(details.length, 2);
      expect((details[1][0]!.value as TextCellValue).value.text, 'منى');
      expect((details[1][1]!.value as TextCellValue).value.text, 'other');
      expect(details[1][7]!.value, isA<IntCellValue>());
      final summary = workbook.tables['Summary']!.rows;
      final hours = summary.last[8]!.value;
      expect(switch (hours) {
        IntCellValue() => hours.value,
        DoubleCellValue() => hours.value,
        _ => null,
      }, 1);
      final texts = summary
          .expand((r) => r)
          .whereType<Data>()
          .map((d) => d.value.toString())
          .join(' ');
      expect(texts, contains(reportRange.label));
      expect(texts, contains('Africa/Cairo'));
    },
  );
  test('formula-like employee content is always encoded as text', () async {
    const name = '=HYPERLINK("https://example.invalid")';
    final report = fixtureReport(
      records: [reportRecord(name: name)],
      employees: const [ReportEmployee('employee', name)],
    );
    final file = await exporter.create(
      report,
      format: ReportFileFormat.excel,
      strings: english,
    );
    final workbook = Excel.decodeBytes(file.bytes);
    expect(workbook.tables['Details']!.rows[1][0]!.value, isA<TextCellValue>());
    expect(
      workbook.tables['Summary']!.rows.any(
        (row) =>
            row.first?.value is TextCellValue &&
            (row.first!.value as TextCellValue).value.text == name,
      ),
      isTrue,
    );
  });
  test('Arabic PDF uses bundled font and handles many detail pages', () async {
    final report = fixtureReport(
      records: List.generate(110, (i) => reportRecord(id: 'record-$i')),
    );
    final file = await exporter.create(
      report,
      format: ReportFileFormat.pdf,
      strings: arabic,
    );
    expect(file.name, endsWith('.pdf'));
    expect(ascii.decode(file.bytes.take(5).toList()), '%PDF-');
    final contents = latin1.decode(file.bytes);
    expect(
      RegExp(r'/Type\s*/Page\b').allMatches(contents).length,
      greaterThan(2),
    );
    expect(contents, contains('/FontFile2'));
    // Optional synthetic artifact for manual visual inspection, never employee data.
    if (Platform.environment['SHIFTLY_REPORT_PREVIEW'] == '1') {
      final directory = Directory('.dart_tool/report-preview')
        ..createSync(recursive: true);
      File('${directory.path}/attendance-ar.pdf').writeAsBytesSync(file.bytes);
    }
  });
  test('empty English PDF still contains a complete valid report', () async {
    final file = await exporter.create(
      fixtureReport(records: []),
      format: ReportFileFormat.pdf,
      strings: english,
    );
    expect(ascii.decode(file.bytes.take(5).toList()), '%PDF-');
  });
}
