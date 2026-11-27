import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/employee_design.dart';
import 'package:shiftly/features/dashboard/domain/entities/manager_dashboard_summary.dart';

List<Widget> buildManagerAttendanceBars(
  BuildContext context,
  ManagerDashboardSummary s,
) {
  final sched = s.scheduledToday;
  final attended = s.clockedInNow + s.completedToday;
  final onTime = (attended - s.lateToday).clamp(0, sched);
  final onTimePct = sched > 0 ? (onTime / sched) : 0.0;
  final latePct = sched > 0 ? (s.lateToday / sched) : 0.0;
  final absentPct = sched > 0 ? (s.missedToday / sched) : 0.0;
  return [
    const SizedBox(height: 16),
    _bar(context, 'On-time rate', onTimePct, const Color(0xFF6EE7B7)),
    const SizedBox(height: 6),
    _bar(context, 'Late rate', latePct, const Color(0xFFFFCC83)),
    const SizedBox(height: 6),
    _bar(context, 'Absence rate', absentPct, const Color(0xFFFF9E9E)),
  ];
}

Widget _bar(BuildContext ctx, String label, double ratio, Color color) => Row(
  children: [
    SizedBox(
      width: 110,
      child: Text(
        ctx.tr(label),
        style: const TextStyle(color: EmployeeDesign.heroText, fontSize: 12),
      ),
    ),
    Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: ratio.clamp(0.0, 1.0),
          minHeight: 6,
          color: color,
          backgroundColor: const Color(0xFF414966),
        ),
      ),
    ),
    const SizedBox(width: 8),
    Text(
      '${(ratio * 100).toStringAsFixed(0)}%',
      style: const TextStyle(color: Colors.white, fontSize: 12),
    ),
  ],
);
