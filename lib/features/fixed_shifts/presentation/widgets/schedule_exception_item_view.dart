import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/schedule_exception.dart';

Widget buildScheduleExceptionItem({
  required BuildContext context,
  required ScheduleException entry,
  required String timezone,
  required String? employeeMembershipId,
  required bool canEdit,
  required bool disabled,
  required VoidCallback onCancel,
}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 8),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '${entry.operationalDate} · ${context.tr(entry.kind == 'SHIFT'
            ? 'One-day shift change'
            : entry.kind == 'DAY_OFF'
            ? 'Employee day off'
            : 'Workspace holiday')}',
      ),
      if (entry.shiftName != null)
        Text('${entry.originalShiftName ?? ''} → ${entry.shiftName}'),
      Text(entry.reason),
      Text(
        context.tr('Created by {manager} on {date}', {
          'manager': entry.creatorName ?? context.tr('Manager'),
          'date': WorkspaceTime.dateTime(entry.createdAt, timezone),
        }),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      if (!entry.active)
        Text('${context.tr('Cancelled')} · ${entry.cancellationReason ?? ''}'),
      if (!entry.active && entry.cancelledAt != null)
        Text(
          context.tr('Cancelled by {manager} on {date}', {
            'manager': entry.cancellerName ?? context.tr('Manager'),
            'date': WorkspaceTime.dateTime(entry.cancelledAt!, timezone),
          }),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      if (canEdit &&
          entry.active &&
          entry.employeeMembershipId == employeeMembershipId)
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: disabled ? null : onCancel,
            child: Text(context.tr('Cancel exception')),
          ),
        ),
    ],
  ),
);
