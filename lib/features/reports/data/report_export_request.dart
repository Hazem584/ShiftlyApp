import 'dart:typed_data';

import 'package:shiftly/features/reports/domain/attendance_report.dart';
import 'package:shiftly/features/reports/domain/report_export.dart';

/// Only data crosses the isolate boundary: never a context, asset bundle,
/// translation callback, repository, or authenticated network client.
class ReportExportRequest {
  const ReportExportRequest({
    required this.report,
    required this.format,
    required this.labels,
    required this.isArabic,
    this.employeeId,
    this.locale,
    this.fontBytes,
  });
  final AttendanceReport report;
  final ReportFileFormat format;
  final Map<String, String> labels;
  final bool isArabic;
  final String? employeeId, locale;
  final Uint8List? fontBytes;
}
