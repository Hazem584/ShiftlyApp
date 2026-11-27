import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shiftly/features/reports/data/attendance_export_data.dart';
import 'package:shiftly/features/reports/data/attendance_pdf_widgets.dart';
import 'package:shiftly/features/reports/domain/report_export.dart';

Future<ReportExportFile> buildPdfReport(
  ExportSheetData data,
  Uint8List fontBytes,
) async {
  final strings = data.strings;
  final font = pw.Font.ttf(ByteData.sublistView(fontBytes));
  final rtl = strings.isArabic;
  final direction = rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;
  final document = pw.Document();
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(24),
      maxPages: 1000,
      theme: pw.ThemeData.withFont(base: font, bold: font),
      textDirection: direction,
      footer: (c) => pw.Text(
        '${c.pageNumber} / ${c.pagesCount}',
        style: const pw.TextStyle(fontSize: 8),
      ),
      build: (_) => [
        pw.Text(
          strings.text('Attendance reports'),
          style: const pw.TextStyle(fontSize: 18),
        ),
        pw.SizedBox(height: 8),
        for (final row in data.metadata) buildPdfMetaRow(row, rtl),
        pw.SizedBox(height: 12),
        buildPdfReportTable(
          ExportSheetData.summaryHeaders.map(strings.text).toList(),
          [...data.summaryRows, ExportSheetData.summaryRow(data.totals)],
          font,
          rtl,
        ),
        pw.NewPage(),
        pw.Text(
          strings.text('Attendance details'),
          style: const pw.TextStyle(fontSize: 16),
        ),
        pw.SizedBox(height: 8),
        if (data.details.isEmpty)
          pw.Text(strings.text('No attendance in this period.'))
        else
          buildPdfReportTable(
            ExportSheetData.detailHeaders.map(strings.text).toList(),
            data.details,
            font,
            rtl,
          ),
      ],
    ),
  );
  return ReportExportFile(
    await document.save(),
    '${data.basename}.pdf',
    'application/pdf',
  );
}
