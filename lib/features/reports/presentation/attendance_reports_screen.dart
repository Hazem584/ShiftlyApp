import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_record_api.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';
import 'package:shiftly/features/reports/domain/report_export.dart';
import 'package:shiftly/features/reports/presentation/attendance_reports_cubit.dart';

class AttendanceReportsScreen extends StatefulWidget {
  const AttendanceReportsScreen({super.key, this.exporter, this.fileDelivery});
  final ReportExporter? exporter;
  final ReportFileDelivery? fileDelivery;

  @override
  State<AttendanceReportsScreen> createState() =>
      _AttendanceReportsScreenState();
}

class _AttendanceReportsScreenState extends State<AttendanceReportsScreen> {
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(context.read<AttendanceReportsCubit>().open());
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('Attendance reports'))),
    body: BlocConsumer<AttendanceReportsCubit, AttendanceReportsState>(
      listenWhen: (before, after) =>
          before.range != null && after.range == null,
      listener: (context, _) =>
          unawaited(context.read<AttendanceReportsCubit>().open()),
      builder: (context, state) {
        final cubit = context.read<AttendanceReportsCubit>();
        final busy = state.loading || _exporting;
        final report = state.report;
        return RefreshIndicator(
          onRefresh: () => _exporting ? Future.value() : cubit.load(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Text(
                context.tr(
                  'Weekly and monthly attendance, lateness and work hours',
                ),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(context.tr('Weekly')),
                    selected: state.period == ReportPeriod.weekly,
                    onSelected: busy
                        ? null
                        : (_) => cubit.selectPeriod(ReportPeriod.weekly),
                  ),
                  ChoiceChip(
                    label: Text(context.tr('Monthly')),
                    selected: state.period == ReportPeriod.monthly,
                    onSelected: busy
                        ? null
                        : (_) => cubit.selectPeriod(ReportPeriod.monthly),
                  ),
                  ActionChip(
                    label: Text(context.tr('Choose period')),
                    avatar: const Icon(Icons.date_range),
                    onPressed: busy ? null : () => _chooseRange(state),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    tooltip: context.tr('Previous period'),
                    onPressed: busy ? null : () => cubit.move(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      state.range?.label ?? '',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                  IconButton(
                    tooltip: context.tr('Next period'),
                    onPressed: busy ? null : () => cubit.move(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              if (state.period == ReportPeriod.weekly)
                Text(context.tr('Weeks run Saturday through Friday.')),
              if (state.loading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (state.failure != null) ...[
                const SizedBox(height: 16),
                Text(context.tr(state.failure!.message)),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FilledButton.icon(
                    onPressed: busy ? null : () => cubit.load(),
                    icon: const Icon(Icons.refresh),
                    label: Text(context.tr('Refresh report')),
                  ),
                ),
              ],
              if (report != null) ...[
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
                    DropdownMenuItem(
                      value: '',
                      child: Text(context.tr('All employees')),
                    ),
                    for (final employee in report.employees)
                      DropdownMenuItem(
                        value: employee.id,
                        child: Text(
                          employee.name,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                _totals(report.totalsFor(state.employeeId)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      key: const Key('report-export-excel'),
                      onPressed: busy
                          ? null
                          : () => _export(ReportFileFormat.excel, state),
                      icon: const Icon(Icons.table_chart_outlined),
                      label: Text(context.tr('Export Excel')),
                    ),
                    OutlinedButton.icon(
                      key: const Key('report-export-pdf'),
                      onPressed: busy
                          ? null
                          : () => _export(ReportFileFormat.pdf, state),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(context.tr('Export PDF')),
                    ),
                    IconButton(
                      tooltip: context.tr('Refresh report'),
                      onPressed: busy ? null : () => cubit.load(),
                      icon: const Icon(Icons.refresh),
                    ),
                    if (_exporting)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr(
                    'Hours include approved closed records only. Open, pending and rejected records do not add hours.',
                  ),
                ),
                Text(
                  context.tr(
                    'Extra shift hours are part of worked hours. Schedule excess is time beyond the scheduled duration of regular shifts; it is an estimate, not payroll approval.',
                  ),
                ),
                Text(
                  context.tr(
                    'Dates use clock-in time in the workspace timezone. Overnight work stays on the clock-in date. Breaks are not deducted.',
                  ),
                ),
                Text(
                  context.tr(
                    'Attendance days count distinct approved clock-in dates per employee. No attendance does not prove absence.',
                  ),
                ),
                const SizedBox(height: 16),
                if (report.recordsFor(state.employeeId).isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(context.tr('No attendance in this period.')),
                  ),
                if (report.rowsFor(state.employeeId).isNotEmpty)
                  PaginatedDataTable(
                    key: ValueKey(
                      'summary-${report.generatedAt}-${state.employeeId}',
                    ),
                    header: Text(context.tr('Employee summary')),
                    rowsPerPage: 10,
                    availableRowsPerPage: const [10],
                    showFirstLastButtons: true,
                    columnSpacing: 20,
                    columns: [
                      for (final title in const [
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
                      ])
                        DataColumn(label: Text(context.tr(title))),
                    ],
                    source: _SummarySource(report.rowsFor(state.employeeId)),
                  ),
                if (report.recordsFor(state.employeeId).isNotEmpty) ...[
                  const SizedBox(height: 16),
                  PaginatedDataTable(
                    key: ValueKey(
                      'details-${report.generatedAt}-${state.employeeId}',
                    ),
                    header: Text(context.tr('Attendance details')),
                    rowsPerPage: 10,
                    availableRowsPerPage: const [10],
                    showFirstLastButtons: true,
                    columnSpacing: 20,
                    columns: [
                      for (final title in const [
                        'Employee',
                        'Clock in',
                        'Clock out',
                        'Review status',
                        'Late minutes',
                        'Recorded work minutes',
                      ])
                        DataColumn(label: Text(context.tr(title))),
                    ],
                    source: _DetailsSource(
                      report,
                      state.employeeId,
                      AppLocalizations.of(context),
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    ),
  );

  Widget _totals(ReportMetrics m) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      for (final item in <(String, String)>[
        ('Employee attendance days', '${m.attendanceDays}'),
        ('Late records', '${m.late}'),
        ('Late minutes', '${m.lateMinutes}'),
        ('Worked hours', (m.workMinutes / 60).toStringAsFixed(2)),
        ('Extra shift hours', (m.extraMinutes / 60).toStringAsFixed(2)),
        ('Schedule excess hours', (m.excessMinutes / 60).toStringAsFixed(2)),
        ('Pending records', '${m.pending}'),
        ('Rejected records', '${m.rejected}'),
        ('Open records', '${m.open}'),
        if (m.missingSchedule > 0) ('Missing schedule', '${m.missingSchedule}'),
        if (m.missingWorkMinutes > 0)
          ('Missing work duration', '${m.missingWorkMinutes}'),
        if (m.unknown > 0) ('Unknown review status', '${m.unknown}'),
      ])
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr(item.$1)),
                Text(item.$2, style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ),
        ),
    ],
  );

  Future<void> _chooseRange(AttendanceReportsState state) async {
    final cubit = context.read<AttendanceReportsCubit>();
    final range = state.range;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: range == null
          ? null
          : DateTimeRange(
              start: DateTime(
                range.start.year,
                range.start.month,
                range.start.day,
              ),
              end: DateTime(range.end.year, range.end.month, range.end.day),
            ),
    );
    if (!mounted || picked == null || !identical(state, cubit.state)) return;
    try {
      await cubit.load(
        range: ReportRange(picked.start, picked.end),
        period: ReportPeriod.custom,
      );
    } on FormatException {
      if (mounted) _message('Choose a period of up to 366 days.');
    }
  }

  Future<void> _export(
    ReportFileFormat format,
    AttendanceReportsState state,
  ) async {
    final report = state.report;
    final cubit = context.read<AttendanceReportsCubit>();
    if (_exporting || report == null || !cubit.canExport(report)) return;
    final strings = ReportLabels(
      AppLocalizations.of(context).text,
      isArabic: Localizations.localeOf(context).languageCode == 'ar',
    );
    final exporter = widget.exporter ?? context.read<ReportExporter>();
    final delivery = widget.fileDelivery ?? context.read<ReportFileDelivery>();
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? const Rect.fromLTWH(0, 0, 1, 1)
        : box.localToGlobal(Offset.zero) & box.size;
    setState(() => _exporting = true);
    bool current() =>
        mounted &&
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
      if (current()) _message('Unable to export report. Try again.');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _message(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr(message))));
}

class _SummarySource extends DataTableSource {
  _SummarySource(this.rows);
  final List<ReportEmployeeRow> rows;
  @override
  DataRow? getRow(int index) {
    if (index >= rows.length) return null;
    final r = rows[index];
    final m = r.metrics;
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

class _DetailsSource extends DataTableSource {
  _DetailsSource(this.report, String? employeeId, this.strings)
    : rows = report.recordsFor(employeeId);
  final AttendanceReport report;
  final AppLocalizations strings;
  final List<AttendanceRecordApi> rows;
  @override
  DataRow? getRow(int index) {
    if (index >= rows.length) return null;
    final r = rows[index];
    return DataRow.byIndex(
      index: index,
      cells: [
        for (final value in [
          r.employee.displayName,
          WorkspaceTime.dateTime(r.clockInAt, report.timezone),
          r.clockOutAt == null
              ? strings.text('Not recorded')
              : WorkspaceTime.dateTime(r.clockOutAt!, report.timezone),
          strings.text(
            r.reviewStatus.name[0].toUpperCase() +
                r.reviewStatus.name.substring(1),
          ),
          r.minutesLate,
          r.workedMinutes ?? strings.text('Not recorded'),
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
