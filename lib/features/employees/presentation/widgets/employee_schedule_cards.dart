import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/widgets/manager_form_page.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/extra_shifts_section.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/work_pattern_section.dart';

List<Widget> buildEmployeeScheduleCards(
  BuildContext context, {
  required Employee employee,
  required String workspaceId,
  required String membershipId,
  required String timezone,
  required bool canEdit,
}) => [
  for (final item in [
    (
      'Baseline schedule',
      'Working weekdays and assignment history',
      WorkPatternSection(
        workspaceId: workspaceId,
        membershipId: membershipId,
        timezone: timezone,
        canEdit: canEdit,
      ),
    ),
    (
      'Extra shifts',
      'Authorizations and recorded extra attendance',
      ExtraShiftsSection(
        workspaceId: workspaceId,
        membershipId: membershipId,
        timezone: timezone,
        canEdit: canEdit,
      ),
    ),
  ]) ...[
    Card(
      child: ListTile(
        title: Text(context.tr(item.$1)),
        subtitle: Text(context.tr(item.$2)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ManagerFormPage(
              title: item.$1,
              subtitle: employee.displayName,
              content: item.$3,
              actions: const [],
            ),
          ),
        ),
      ),
    ),
    const SizedBox(height: 14),
  ],
];
