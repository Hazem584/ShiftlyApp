import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';

class EmployeeDashboardShiftCard extends StatelessWidget {
  const EmployeeDashboardShiftCard({
    super.key,
    required this.title,
    required this.shift,
    required this.timezone,
    this.attendance,
  });
  final String title;
  final EmployeeDashboardShift? shift;
  final String timezone;
  final DashboardAttendance? attendance;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(context.tr(title), style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.s),
      SurfaceCard(
        child: shift == null
            ? Text(
                context.tr('No shift scheduled.'),
                style: const TextStyle(color: AppColors.textSecondary),
              )
            : Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: AppColors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('{value1} – {value2}', {
                        'value1': (WorkspaceTime.time(
                          shift!.startsAt,
                          timezone,
                          locale: Localizations.localeOf(context).toString(),
                        )).toString(),
                        'value2': (WorkspaceTime.time(
                          shift!.endsAt,
                          timezone,
                          locale: Localizations.localeOf(context).toString(),
                        )).toString(),
                      }),
                      maxLines: 2,
                    ),
                  ),
                  if (attendance != null)
                    Text(
                      context.tr(switch (attendance!.status) {
                        DashboardAttendanceStatus.clockedIn => 'Clocked in',
                        DashboardAttendanceStatus.completed => 'Completed',
                        DashboardAttendanceStatus.unknown => 'Recorded',
                      }),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                ],
              ),
      ),
    ],
  );
}
