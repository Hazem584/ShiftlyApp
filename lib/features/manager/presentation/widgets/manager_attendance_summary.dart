import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/features/dashboard/domain/entities/manager_dashboard_summary.dart';

class ManagerAttendanceSummary extends StatelessWidget {
  const ManagerAttendanceSummary({required this.summary, super.key});
  final ManagerDashboardSummary summary;
  @override
  Widget build(BuildContext context) => Container(
    key: const Key('manager-attendance-summary'),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppPalette.of(context).brandBackground,
      borderRadius: BorderRadius.circular(20),
    ),
    child: DefaultTextStyle.merge(
      style: const TextStyle(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Today’s attendance'),
            style: const TextStyle(
              color: Color(0xFFC7CEED),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 32,
            runSpacing: 20,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.clockedInNow.toString(),
                    style: const TextStyle(
                      fontSize: 42,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('of {count} scheduled', {
                      'count': summary.scheduledToday.toString(),
                    }),
                    style: const TextStyle(
                      color: Color(0xFFD1D7EE),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('{count} late', {
                      'count': summary.lateToday.toString(),
                    }),
                    style: const TextStyle(
                      color: Color(0xFFF9D092),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('{count} on leave', {
                      'count': summary.onApprovedLeave.toString(),
                    }),
                    style: const TextStyle(
                      color: Color(0xFFD1D7EE),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
