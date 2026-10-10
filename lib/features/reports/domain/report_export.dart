import 'dart:typed_data';

import 'package:shiftly/features/reports/domain/attendance_report.dart';

enum ReportFileFormat { excel, pdf }

class ReportExportFile {
  const ReportExportFile(this.bytes, this.name, this.mimeType);
  final Uint8List bytes;
  final String name, mimeType;
}

class ReportLabels {
  const ReportLabels(this.text, {this.isArabic = false});
  final String Function(String) text;
  final bool isArabic;
}

class ReportShareOrigin {
  const ReportShareOrigin(this.x, this.y, this.width, this.height);
  final double x, y, width, height;
}

abstract interface class ReportExporter {
  Future<ReportExportFile> create(
    AttendanceReport report, {
    required ReportFileFormat format,
    required ReportLabels strings,
    String? employeeId,
  });
}

abstract interface class ReportFileDelivery {
  Future<void> deliver(
    ReportExportFile file, {
    required ReportShareOrigin origin,
    required bool Function() isCurrent,
  });
}
