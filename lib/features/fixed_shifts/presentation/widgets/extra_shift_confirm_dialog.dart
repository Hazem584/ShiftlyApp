import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_dialog.dart';

Future<bool?> showExtraShiftConfirmDialog({
  required BuildContext context,
  required List<ShiftTemplate> templates,
  required String templateId,
  required Map<String, Object?> payload,
  required String timezone,
  required String reason,
  required String text,
  required bool actual,
}) {
  final locale = Localizations.localeOf(context).toString();
  final templateName = templates.firstWhere((t) => t.id == templateId).name;
  final actualDetails = actual
      ? context.tr('\nClock-in: {start}\nClock-out: {end}', {
          'start': WorkspaceTime.dateTime(
            DateTime.parse(payload['actualClockInAt'] as String),
            timezone,
            locale: locale,
          ),
          'end': WorkspaceTime.dateTime(
            DateTime.parse(payload['actualClockOutAt'] as String),
            timezone,
            locale: locale,
          ),
        })
      : '';
  return showDialog<bool>(
    context: context,
    builder: (c) => ManagerDialog(
      title: Text(context.tr('Confirm extra shift')),
      scrollable: true,
      content: Text(
        context.tr(
          '{value1}\n{value2} · {value3}\n{value4}\n{value5}{value6}',
          {
            'value1': templateName,
            'value2': payload['operationalDate'].toString(),
            'value3': timezone,
            'value4': context.tr(reason),
            'value5': text,
            'value6': actualDetails,
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: Text(context.tr('Back')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(c, true),
          child: Text(context.tr('Confirm')),
        ),
      ],
    ),
  );
}
