import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_calendar_entry.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_controls_repository.dart';

String attendanceDecisionLabel(String status) => switch (status) {
  'PRESENT' => 'Present',
  'LATE' => 'Late',
  'ABSENT' => 'Absent',
  'LEAVE' => 'Leave',
  _ => 'Use recorded attendance',
};

Future<void> performAttendanceDecisionSave({
  required AttendanceControlsRepository repository,
  required String workspaceId,
  required int year,
  required int month,
  required int revision,
  required bool closeMonth,
  required AttendanceCalendarEntry? entry,
  required DateTime? date,
  required String status,
  required String reason,
}) async {
  if (entry == null) {
    await repository.decideMonth(
      workspaceId: workspaceId,
      year: year,
      month: month,
      revision: revision,
      close: closeMonth,
      reason: reason,
    );
  } else {
    final d = date!;
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    await repository.decideDay(
      workspaceId: workspaceId,
      employeeMembershipId: entry.employeeMembershipId,
      date: dateStr,
      status: status,
      reason: reason,
      revision: revision,
    );
  }
}

List<Widget> buildAttendanceDecisionContent({
  required BuildContext context,
  required AttendanceCalendarEntry? entry,
  required DateTime? date,
  required int year,
  required int month,
  required bool closeMonth,
  required String status,
  required bool saving,
  required ValueChanged<String?> onStatusChanged,
  required TextEditingController reasonController,
  required String? error,
}) => [
  Text(
    date?.toIso8601String().split('T').first ??
        '$year-${month.toString().padLeft(2, '0')}',
  ),
  const SizedBox(height: 8),
  if (entry != null) ...[
    Text(entry.employee.displayName),
    const SizedBox(height: 12),
    DropdownButtonFormField<String>(
      initialValue: status,
      isExpanded: true,
      decoration: InputDecoration(labelText: context.tr('Attendance status')),
      items: const ['AUTO', 'PRESENT', 'LATE', 'ABSENT', 'LEAVE']
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(context.tr(attendanceDecisionLabel(s))),
            ),
          )
          .toList(),
      onChanged: saving ? null : onStatusChanged,
    ),
    const SizedBox(height: 12),
    Text(
      context.tr(
        'The day status changes; recorded clock times remain in the audit history.',
      ),
    ),
  ] else
    Text(
      context.tr(
        closeMonth
            ? 'Review the monthly totals before closing. Changes require reopening the month with a reason.'
            : 'Reopening allows attendance changes. The previous approval remains in the audit history.',
      ),
    ),
  const SizedBox(height: 12),
  TextFormField(
    controller: reasonController,
    enabled: !saving,
    minLines: 2,
    maxLines: 4,
    maxLength: 1000,
    decoration: InputDecoration(labelText: context.tr('Reason')),
    validator: (v) => (v?.trim().length ?? 0) < 3
        ? context.tr('Enter a reason of at least 3 characters.')
        : null,
  ),
  if (error != null)
    Text(
      context.tr(error),
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
];
