import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';
import 'package:shiftly/features/reports/domain/report_export.dart';

import 'attendance_export_builder.dart';
import 'report_export_labels.dart';
import 'report_export_request.dart';

class AttendanceReportExporter implements ReportExporter {
  @override
  Future<ReportExportFile> create(
    AttendanceReport report, {
    required ReportFileFormat format,
    required ReportLabels strings,
    String? employeeId,
  }) async {
    // A translation function can capture an entire widget/service graph. Only
    // its resolved strings are sent; rootBundle is accessed on the main isolate.
    final labels = {
      for (final key in reportExportLabelKeys) key: strings.text(key),
    };
    Uint8List? fontBytes;
    if (format == ReportFileFormat.pdf) {
      final font = await rootBundle.load('assets/fonts/Cairo-Variable.ttf');
      fontBytes = font.buffer.asUint8List(
        font.offsetInBytes,
        font.lengthInBytes,
      );
    }
    return compute(
      buildReportExport,
      ReportExportRequest(
        report: report,
        format: format,
        labels: labels,
        isArabic: strings.isArabic,
        employeeId: employeeId,
        fontBytes: fontBytes,
        locale: Intl.getCurrentLocale(),
      ),
      debugLabel: 'shiftly.report.export',
    );
  }
}
