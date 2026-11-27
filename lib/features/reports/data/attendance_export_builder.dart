import 'package:intl/intl.dart';
import 'package:shiftly/features/reports/data/attendance_excel_builder.dart';
import 'package:shiftly/features/reports/data/attendance_export_data.dart';
import 'package:shiftly/features/reports/data/attendance_pdf_builder.dart';
import 'package:shiftly/features/reports/domain/report_export.dart';

import 'report_export_request.dart';

Future<ReportExportFile> buildReportExport(ReportExportRequest request) =>
    AttendanceExportBuilder().create(request);

class AttendanceExportBuilder {
  Future<ReportExportFile> create(ReportExportRequest request) async {
    Intl.defaultLocale = request.locale;
    final strings = ReportLabels(
      (key) => request.labels[key] ?? key,
      isArabic: request.isArabic,
    );
    final data = ExportSheetData(
      ReportReportContext(request.report, request.employeeId, strings),
    );
    if (request.format == ReportFileFormat.excel) {
      return buildExcelReport(data);
    }
    return buildPdfReport(data, request.fontBytes!);
  }
}
