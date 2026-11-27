import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/eligible_shift_occurrence.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

import 'employee_scheduled_shift_screen.dart';
import 'employee_shift_details_screen.dart';
import 'employee_tile.dart';

List<Widget> buildScheduleOccurrenceTiles({
  required BuildContext context,
  required List<EligibleShiftOccurrence> entries,
  required DateTime month,
  required String locale,
  required String timezone,
}) => [
  for (final e in entries.where(
    (e) =>
        DateTime.parse(e.operationalDate).month == month.month &&
        DateTime.parse(e.operationalDate).year == month.year,
  )) ...[
    EmployeeTile(
      key: Key('schedule-occurrence-${e.identity}'),
      title:
          '${DateFormat.MMMEd(locale).format(DateTime.parse(e.operationalDate))} · ${e.template.name}',
      subtitle:
          '${WorkspaceTime.time(e.scheduledStartAt, timezone, locale: locale)}–${WorkspaceTime.time(e.scheduledEndAt, timezone, locale: locale)} · ${context.tr(e.alreadyUsed
              ? 'Recorded'
              : e.scheduleExceptionId != null
              ? 'Date-specific change'
              : e.occurrenceKind == 'EXTRA'
              ? 'Authorized extra'
              : 'Baseline assignment')}',
      icon: e.occurrenceKind == 'EXTRA'
          ? Icons.add
          : Icons.calendar_today_outlined,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              EmployeeShiftDetailsScreen(entry: e, timezone: timezone),
        ),
      ),
    ),
    const SizedBox(height: 14),
  ],
];

List<Widget> buildScheduledShiftTiles({
  required BuildContext context,
  required List<ShiftRecord> visibleShifts,
  required List<EligibleShiftOccurrence> entries,
  required String locale,
  required String timezone,
}) => [
  for (final shift in visibleShifts.where(
    (s) => !entries.any(
      (e) =>
          e.operationalDate == WorkspaceTime.dateKey(s.startsAt, timezone) &&
          ((e.assignmentId != null && e.assignmentId == s.assignmentId) ||
              (e.extraAuthorizationId != null &&
                  e.extraAuthorizationId == s.extraAuthorizationId)),
    ),
  )) ...[
    EmployeeTile(
      title:
          '${DateFormat.MMMEd(locale).format(WorkspaceTime.inWorkspace(shift.startsAt, timezone))} · ${shift.notes?.trim().isNotEmpty == true ? shift.notes : context.tr('Scheduled shift')}',
      subtitle:
          '${WorkspaceTime.time(shift.startsAt, timezone, locale: locale)}–${WorkspaceTime.time(shift.endsAt, timezone, locale: locale)} · ${context.tr(shift.extraAuthorizationId != null ? 'Authorized extra' : 'Baseline assignment')}',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              EmployeeScheduledShiftScreen(shift: shift, timezone: timezone),
        ),
      ),
    ),
    const SizedBox(height: 14),
  ],
];
