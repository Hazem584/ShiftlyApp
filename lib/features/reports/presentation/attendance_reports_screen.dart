import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/features/reports/domain/report_export.dart';
import 'package:shiftly/features/reports/presentation/attendance_report_actions.dart';
import 'package:shiftly/features/reports/presentation/attendance_report_controls.dart';
import 'package:shiftly/features/reports/presentation/attendance_report_overview.dart';
import 'package:shiftly/features/reports/presentation/attendance_report_tables.dart';
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
    appBar: AppBar(title: Text(context.tr('Attendance summary'))),
    body: BlocConsumer<AttendanceReportsCubit, AttendanceReportsState>(
      listenWhen: (b, a) => b.range != null && a.range == null,
      listener: (context, _) =>
          unawaited(context.read<AttendanceReportsCubit>().open()),
      builder: (context, state) {
        final cubit = context.read<AttendanceReportsCubit>();
        final busy = state.loading || _exporting, report = state.report;
        return RefreshIndicator(
          onRefresh: () => _exporting ? Future.value() : cubit.load(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: ListView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  ...buildReportPeriodControls(
                    context,
                    state: state,
                    busy: busy,
                    onChooseRange: () =>
                        chooseAttendanceReportRange(context, state, _message),
                  ),
                  if (state.loading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: AppContentLoading(),
                    ),
                  if (state.failure != null)
                    ...buildReportFailureBanner(
                      context,
                      state.failure!.message,
                      busy: busy,
                      onRefresh: cubit.load,
                    ),
                  if (report != null) ...[
                    ...buildReportOverviewSection(
                      context,
                      report: report,
                      state: state,
                      busy: busy,
                      exporting: _exporting,
                      onExport: (format) => _export(format, state),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ExpansionTile(
                        key: const PageStorageKey('attendance-report-tables'),
                        title: Text(context.tr('Attendance details')),
                        children: buildReportTablesSection(
                          context,
                          report: report,
                          employeeId: state.employeeId,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  Future<void> _export(ReportFileFormat f, AttendanceReportsState state) async {
    if (_exporting) return;
    await runAttendanceReportExport(
      context: context,
      format: f,
      state: state,
      customExporter: widget.exporter,
      customDelivery: widget.fileDelivery,
      setExporting: (v) => setState(() => _exporting = v),
      onMessage: _message,
    );
  }

  void _message(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr(message))));
}
