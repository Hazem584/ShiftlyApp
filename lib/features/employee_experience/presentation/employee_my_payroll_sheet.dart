import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/dashboard/domain/entities/employee_dashboard_summary.dart';

Future<void> showEmployeeMyPayrollSheet(
  BuildContext context,
  EmployeeDashboardSummary s,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _EmployeeMyPayrollSheet(summary: s),
);

class _EmployeeMyPayrollSheet extends StatelessWidget {
  const _EmployeeMyPayrollSheet({required this.summary});
  final EmployeeDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final c = summary.currency;
    String money(double v) => '${v.toStringAsFixed(2)} $c';
    String hrs(int m) => '${(m / 60).toStringAsFixed(1)} h';
    final rows = [
      (
        context.tr('Monthly salary'),
        summary.monthlySalary != null
            ? money(summary.monthlySalary!)
            : context.tr('Not set'),
      ),
      (
        context.tr('Hourly rate'),
        summary.hourlyRate > 0
            ? money(summary.hourlyRate)
            : context.tr('Not set'),
      ),
      (context.tr('Worked hours'), hrs(summary.workedMinutesMonth)),
      (context.tr('Extra shift hours'), hrs(summary.overtimeMinutesMonth)),
      (context.tr('Late minutes'), '${summary.lateMinutesMonth} min'),
      (context.tr('Base pay'), money(summary.basePayMonth)),
      (context.tr('Deductions'), '- ${money(summary.deductionsMonth)}'),
      (context.tr('Overtime pay'), '+ ${money(summary.overtimePayMonth)}'),
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('My salary & earnings'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(r.$1), Text(r.$2)],
                ),
              ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('Net payable'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  money(summary.netPayMonth),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
