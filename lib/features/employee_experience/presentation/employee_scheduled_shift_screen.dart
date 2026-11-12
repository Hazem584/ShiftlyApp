import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/work_duration.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

import 'employee_page.dart';
import 'employee_tile.dart';

class EmployeeScheduledShiftScreen extends StatelessWidget {
  const EmployeeScheduledShiftScreen({
    required this.shift,
    required this.timezone,
    super.key,
  });
  final ShiftRecord shift;
  final String timezone;
  @override
  Widget build(BuildContext context) => EmployeePage(
    title: 'Shift details',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '${WorkspaceTime.dateKey(shift.startsAt, timezone)} · $timezone',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        EmployeeTile(
          title: shift.notes ?? context.tr('Scheduled shift'),
          subtitle:
              '${WorkspaceTime.time(shift.startsAt, timezone)} – ${WorkspaceTime.time(shift.endsAt, timezone)}',
        ),
        const SizedBox(height: 16),
        EmployeeTile(
          icon: Icons.coffee_outlined,
          title: context.tr('Break'),
          subtitle: workDuration(
            shift.breakMinutes,
            arabic: Localizations.localeOf(context).languageCode == 'ar',
          ),
        ),
        const SizedBox(height: 24),
        Text(
          context.tr(
            'Check-in availability is confirmed for the current occurrence. Refresh My Shifts when its check-in window opens.',
          ),
        ),
      ],
    ),
  );
}
