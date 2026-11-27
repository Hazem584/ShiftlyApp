import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';
import 'package:shiftly/features/reports/domain/report_export.dart';
import 'package:shiftly/features/reports/presentation/attendance_reports_cubit.dart';

Future<void> chooseAttendanceReportRange(
  BuildContext context,
  AttendanceReportsState state,
  void Function(String) onMessage,
) async {
  final cubit = context.read<AttendanceReportsCubit>();
  final r = state.range;
  final picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
    initialDateRange: r == null
        ? null
        : DateTimeRange(
            start: DateTime(r.start.year, r.start.month, r.start.day),
            end: DateTime(r.end.year, r.end.month, r.end.day),
          ),
  );
  if (!context.mounted || picked == null || !identical(state, cubit.state)) {
    return;
  }
  try {
    await cubit.load(
      range: ReportRange(picked.start, picked.end),
      period: ReportPeriod.custom,
    );
  } on FormatException {
    if (context.mounted) onMessage('Choose a period of up to 366 days.');
  }
}

Future<void> runAttendanceReportExport({
  required BuildContext context,
  required ReportFileFormat format,
  required AttendanceReportsState state,
  required ReportExporter? customExporter,
  required ReportFileDelivery? customDelivery,
  required void Function(bool) setExporting,
  required void Function(String) onMessage,
}) async {
  final report = state.report;
  final cubit = context.read<AttendanceReportsCubit>();
  if (report == null || !cubit.canExport(report)) return;
  final strings = ReportLabels(
    AppLocalizations.of(context).text,
    isArabic: Localizations.localeOf(context).languageCode == 'ar',
  );
  final exporter = customExporter ?? context.read<ReportExporter>();
  final delivery = customDelivery ?? context.read<ReportFileDelivery>();
  final box = context.findRenderObject() as RenderBox?;
  final origin = box == null
      ? const Rect.fromLTWH(0, 0, 1, 1)
      : box.localToGlobal(Offset.zero) & box.size;
  setExporting(true);
  bool current() =>
      context.mounted &&
      cubit.canExport(report) &&
      cubit.state.employeeId == state.employeeId;
  try {
    final file = await exporter.create(
      report,
      format: format,
      strings: strings,
      employeeId: state.employeeId,
    );
    if (!current()) return;
    await delivery.deliver(
      file,
      origin: ReportShareOrigin(
        origin.left,
        origin.top,
        origin.width,
        origin.height,
      ),
      isCurrent: current,
    );
  } catch (_) {
    if (current()) onMessage('Unable to export report. Try again.');
  } finally {
    if (context.mounted) setExporting(false);
  }
}
