import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/manager/presentation/widgets/manager_attendance_record_tile.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';

/// Mobile report cards preserve every metric without squeezing wide tables.
class CompactAttendanceReport extends StatefulWidget {
  const CompactAttendanceReport({
    required this.report,
    this.employeeId,
    super.key,
  });
  final AttendanceReport report;
  final String? employeeId;
  @override
  State<CompactAttendanceReport> createState() =>
      _CompactAttendanceReportState();
}

class _CompactAttendanceReportState extends State<CompactAttendanceReport> {
  int _employeePage = 0, _recordPage = 0;
  @override
  void didUpdateWidget(covariant CompactAttendanceReport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.report != widget.report ||
        oldWidget.employeeId != widget.employeeId) {
      _employeePage = 0;
      _recordPage = 0;
    }
  }

  Widget _pages(int count, int page, ValueChanged<int> change) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    spacing: 12,
    children: [
      TextButton(
        onPressed: page == 0 ? null : () => change(page - 1),
        child: Text(context.tr('Previous')),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          context.tr('Page {value1} of {value2}', {
            'value1': (page + 1).toString(),
            'value2': ((count / 10).ceil()).toString(),
          }),
        ),
      ),
      TextButton(
        onPressed: (page + 1) * 10 >= count ? null : () => change(page + 1),
        child: Text(context.tr('Next')),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    final rows = widget.report.rowsFor(widget.employeeId);
    final records = widget.report.recordsFor(widget.employeeId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr('Employee summary'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        for (final row in rows.skip(_employeePage * 10).take(10))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.employee.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final metric in <(String, String)>[
                    ('Attendance days', row.metrics.attendanceDays.toString()),
                    ('Approved records', row.metrics.approved.toString()),
                    ('Pending records', row.metrics.pending.toString()),
                    ('Rejected records', row.metrics.rejected.toString()),
                    ('Open records', row.metrics.open.toString()),
                    ('Late records', row.metrics.late.toString()),
                    ('Late minutes', row.metrics.lateMinutes.toString()),
                    (
                      'Worked hours',
                      (row.metrics.workMinutes / 60).toStringAsFixed(2),
                    ),
                    (
                      'Extra shift hours',
                      (row.metrics.extraMinutes / 60).toStringAsFixed(2),
                    ),
                    (
                      'Schedule excess hours',
                      (row.metrics.excessMinutes / 60).toStringAsFixed(2),
                    ),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 12,
                        children: [
                          Text('${context.tr(metric.$1)}:'),
                          Text(
                            metric.$2,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (rows.length > 10)
          _pages(
            rows.length,
            _employeePage,
            (v) => setState(() => _employeePage = v),
          ),
        const SizedBox(height: 20),
        Text(
          context.tr('Attendance details'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        for (final record in records.skip(_recordPage * 10).take(10))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ManagerAttendanceRecordTile(
              record: record,
              timezone: widget.report.timezone,
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => SafeArea(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ManagerAttendanceRecordTile(
                            record: record,
                            timezone: widget.report.timezone,
                          ),
                          if (record.rejectionReason != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              '${context.tr('Reason')}: ${record.rejectionReason!}',
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(context.tr('Close')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (records.length > 10)
          _pages(
            records.length,
            _recordPage,
            (v) => setState(() => _recordPage = v),
          ),
      ],
    );
  }
}
