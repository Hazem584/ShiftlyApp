import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';
import 'package:shiftly/features/reports/domain/report_export.dart';
import 'package:shiftly/features/reports/presentation/attendance_report_totals.dart';
import 'package:shiftly/features/reports/presentation/attendance_reports_cubit.dart';
import 'package:shiftly/features/reports/presentation/widgets/report_analytics_card.dart';

List<Widget> buildReportOverviewSection(
  BuildContext context, {
  required AttendanceReport report,
  required AttendanceReportsState state,
  required bool busy,
  required bool exporting,
  required void Function(ReportFileFormat) onExport,
}) {
  final cubit = context.read<AttendanceReportsCubit>();
  return [
    const SizedBox(height: 16),
    DropdownButtonFormField<String>(
      key: ValueKey('${report.generatedAt}-${state.employeeId}'),
      initialValue: state.employeeId ?? '',
      isExpanded: true,
      decoration: InputDecoration(
        labelText: context.tr('Employee filter'),
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(value: '', child: Text(context.tr('All employees'))),
        for (final emp in report.employees)
          DropdownMenuItem(
            value: emp.id,
            child: Text(emp.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: busy
          ? null
          : (id) => cubit.selectEmployee(id == '' ? null : id),
    ),
    const SizedBox(height: 12),
    Text('${report.workspaceName} • ${report.timezone}'),
    Text(
      '${context.tr('Generated at')}: ${WorkspaceTime.dateTime(report.generatedAt, report.timezone, locale: Localizations.localeOf(context).languageCode)}',
    ),
    const SizedBox(height: 12),
    ReportAnalyticsCard(report: report, employeeId: state.employeeId),
    const SizedBox(height: 12),
    Card(
      child: ExpansionTile(
        key: const PageStorageKey('attendance-report-totals'),
        title: Text(context.tr('Report totals')),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: AttendanceReportTotals(
              metrics: report.totalsFor(state.employeeId),
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 12),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          key: const Key('report-export-excel'),
          onPressed: busy ? null : () => onExport(ReportFileFormat.excel),
          icon: const Icon(Icons.table_chart_outlined),
          label: Text(context.tr('Export Excel')),
        ),
        OutlinedButton.icon(
          key: const Key('report-export-pdf'),
          onPressed: busy ? null : () => onExport(ReportFileFormat.pdf),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: Text(context.tr('Export PDF')),
        ),
        IconButton(
          tooltip: context.tr('Refresh report'),
          onPressed: busy ? null : () => cubit.load(),
          icon: const Icon(Icons.refresh),
        ),
        if (exporting)
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    ),
  ];
}
