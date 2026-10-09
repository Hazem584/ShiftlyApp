import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/utils/dashboard_activity_section_formatters.dart';

class DashboardShiftTile extends StatelessWidget {
  const DashboardShiftTile({
    super.key,
    required this.shift,
    required this.timezone,
  });
  final DashboardShiftPreview shift;
  final String timezone;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    leading: CircleAvatar(
      backgroundColor: AppColors.field,
      foregroundColor: AppColors.ink,
      child: Text(shift.employee.fullName.characters.first.toUpperCase()),
    ),
    title: Text(
      shift.employee.fullName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    subtitle: Text(
      '${WorkspaceTime.time(shift.startsAt, timezone, locale: Localizations.localeOf(context).toString())} – '
      '${WorkspaceTime.time(shift.endsAt, timezone, locale: Localizations.localeOf(context).toString())}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: Text(
      dashboardActivitySectionAttendanceLabel(shift.attendance),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}
