import 'package:flutter/material.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';

import '../domain/operations_repository.dart';

OperationMap opMap(Object? v) => Map<String, Object?>.from(v as Map);
List<OperationMap> opRows(Object? v) => (v as List).map(opMap).toList();
String opDate(Object? v, String zone) =>
    WorkspaceTime.dateTime(DateTime.parse(v as String), zone);
String occurrenceLabel(OperationMap v, String zone) =>
    '${v['name']} · ${opDate(v['startsAt'], zone)} → ${opDate(v['endsAt'], zone)}';
String operationError(Object e) => e is Failure
    ? e.message
    : e is FormatException
    ? e.message
    : 'Could not complete this request. Refresh and try again.';
Future<DateTime?> chooseOperationTime(
  BuildContext context,
  String timezone, {
  DateTime? initial,
}) async {
  final local = WorkspaceTime.inWorkspace(initial ?? DateTime.now(), timezone);
  final date = await showDatePicker(
    context: context,
    initialDate: DateTime(local.year, local.month, local.day),
    firstDate: DateTime.now().subtract(const Duration(days: 14)),
    lastDate: DateTime.now().add(const Duration(days: 100)),
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: local.hour, minute: local.minute),
  );
  if (time == null) return null;
  final utc = WorkspaceTime.wallTimeToUtc(
    date: date,
    hour: time.hour,
    minute: time.minute,
    timezoneName: timezone,
  );
  final checked = WorkspaceTime.inWorkspace(utc, timezone);
  if (checked.year != date.year ||
      checked.month != date.month ||
      checked.day != date.day ||
      checked.hour != time.hour ||
      checked.minute != time.minute) {
    throw const FormatException(
      'This local time does not exist because of a clock change. Choose another time.',
    );
  }
  return utc;
}

Future<String?> operationNote(BuildContext context) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(c.tr('Progress note')),
      content: TextField(
        controller: controller,
        maxLength: 2000,
        minLines: 2,
        maxLines: 5,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: Text(c.tr('Cancel')),
        ),
        FilledButton(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              Navigator.pop(c, controller.text.trim());
            }
          },
          child: Text(c.tr('Save')),
        ),
      ],
    ),
  );
  // Dialog route can keep the field alive through its closing animation.
  Future<void>.delayed(const Duration(seconds: 1), controller.dispose);
  return result;
}

const planningReasonLabels = {
  'UNAVAILABLE': 'Not available for the entire shift',
  'MISSING_SKILLS': 'Required skills missing',
  'APPROVED_LEAVE': 'Approved leave',
  'OVERLAP': 'Another assigned shift overlaps',
  'MINIMUM_REST': 'Insufficient rest between shifts',
  'DAILY_HOURS': 'Daily hours limit',
  'WEEKLY_HOURS': 'Weekly hours limit',
  'WEEKLY_REST': 'Weekly rest required',
  'NO_ELIGIBLE_EMPLOYEE': 'No eligible employee',
  'AVAILABLE': 'Available for the entire shift',
  'SKILLS_MATCH': 'Required skills match',
  'NO_CONFLICT': 'No schedule conflict',
  'WITHIN_HOURS_AND_REST': 'Within hours and rest limits',
  'BALANCED_WORKLOAD': 'Balances assigned hours and night / weekend duties',
};
String planningReason(BuildContext context, String code) {
  final parts = code.split(':');
  if (parts.length == 2) {
    final label = switch (parts.first) {
      'LOAD_MINUTES' => 'Assigned work in review window: {value} minutes',
      'NIGHT_COUNT' => 'Night shifts in review window: {value}',
      'WEEKEND_COUNT' => 'Friday / Saturday shifts in review window: {value}',
      _ => null,
    };
    if (label != null) {
      return context.tr(label, {'value': parts[1]});
    }
  }
  return context.tr(planningReasonLabels[code] ?? code);
}
