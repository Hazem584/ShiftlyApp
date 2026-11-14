import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/employee_design.dart';
import 'package:shiftly/features/dashboard/domain/entities/manager_dashboard_summary.dart';

class ManagerAttendanceOverview extends StatelessWidget {
  const ManagerAttendanceOverview({required this.summary, super.key});
  final ManagerDashboardSummary summary;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? EmployeeDesign.heroDark
          : EmployeeDesign.hero,
      borderRadius: BorderRadius.circular(20),
    ),
    child: IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('TODAY’S ATTENDANCE'),
                  style: const TextStyle(
                    color: EmployeeDesign.heroText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${summary.clockedInNow}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
                Text(
                  context.tr('of {count} on shift', {
                    'count': '${summary.scheduledToday}',
                  }),
                  style: const TextStyle(color: EmployeeDesign.heroText),
                ),
              ],
            ),
          ),
          const VerticalDivider(color: Color(0xFF414966), width: 32),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('{count} late', {'count': '${summary.lateToday}'}),
                  style: const TextStyle(
                    color: Color(0xFFFFCC83),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('{count} on leave', {
                    'count': '${summary.onApprovedLeave}',
                  }),
                  style: const TextStyle(color: EmployeeDesign.heroText),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
