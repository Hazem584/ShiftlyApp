import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';

class ReportAnalyticsCard extends StatelessWidget {
  const ReportAnalyticsCard({
    super.key,
    required this.report,
    required this.employeeId,
  });
  final AttendanceReport report;
  final String? employeeId;

  @override
  Widget build(BuildContext context) {
    final m = report.totalsFor(employeeId);
    final rows = report.rowsFor(employeeId);
    final totalDays = m.attendanceDays + m.absentDays;
    final onTimeDays = (m.attendanceDays - m.late).clamp(0, m.attendanceDays);
    final onTimePct = totalDays > 0 ? (onTimeDays / totalDays) : 0.0;
    final latePct = totalDays > 0 ? (m.late / totalDays) : 0.0;
    final absentPct = totalDays > 0 ? (m.absentDays / totalDays) : 0.0;
    final netPayroll = rows.fold<double>(0, (sum, r) => sum + r.netPay);
    final deductions = rows.fold<double>(0, (sum, r) => sum + r.deductions);
    final overtime = rows.fold<double>(0, (sum, r) => sum + r.overtimePay);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('Attendance & payroll analytics'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _bar(context, 'On-time rate', onTimePct, Colors.green),
            const SizedBox(height: 8),
            _bar(context, 'Late rate', latePct, Colors.orange),
            const SizedBox(height: 8),
            _bar(context, 'Absence rate', absentPct, Colors.redAccent),
            const Divider(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Text(
                  '${context.tr('Deductions')}: ${deductions.toStringAsFixed(2)}',
                ),
                Text(
                  '${context.tr('Overtime pay')}: ${overtime.toStringAsFixed(2)}',
                ),
                Text(
                  '${context.tr('Net payable')}: ${netPayroll.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar(BuildContext ctx, String label, double ratio, Color color) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(ctx.tr(label))),
              const SizedBox(width: 8),
              Text('${(ratio * 100).toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 8,
              color: color,
            ),
          ),
        ],
      );
}
