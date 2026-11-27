import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';

Future<DateTime?> pickCorrectionWallTimeToUtc(
  BuildContext context,
  DateTime currentUtc,
  String timezone,
) async {
  final current = WorkspaceTime.inWorkspace(currentUtc, timezone);
  final today = WorkspaceTime.inWorkspace(DateTime.now(), timezone);
  final date = await showDatePicker(
    context: context,
    initialDate: current,
    firstDate: DateTime(current.year - 1),
    lastDate: today,
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
  );
  if (time == null || !context.mounted) return null;
  return WorkspaceTime.wallTimeToUtc(
    date: date,
    hour: time.hour,
    minute: time.minute,
    timezoneName: timezone,
  );
}

class CorrectionRequestFormBody extends StatelessWidget {
  const CorrectionRequestFormBody({
    super.key,
    required this.formKey,
    required this.record,
    required this.timezone,
    required this.start,
    required this.end,
    required this.busy,
    required this.reasonController,
    required this.error,
    required this.onPickStart,
    required this.onPickEnd,
  });
  final GlobalKey<FormState> formKey;
  final AttendanceRecordApi record;
  final String timezone;
  final DateTime start, end;
  final bool busy;
  final TextEditingController reasonController;
  final String? error;
  final VoidCallback onPickStart, onPickEnd;

  String _format(BuildContext context, DateTime value) =>
      WorkspaceTime.dateTime(
        value,
        timezone,
        locale: Localizations.localeOf(context).toString(),
      );

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 460,
    child: SingleChildScrollView(
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(
                'Your manager will review these times before they change.',
              ),
            ),
            const SizedBox(height: 12),
            Text(context.tr('Original times')),
            Text(
              '${_format(context, record.clockInAt)}\n${_format(context, record.clockOutAt!)}',
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('Requested clock in')),
              subtitle: Text(_format(context, start)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: busy ? null : onPickStart,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('Requested clock out')),
              subtitle: Text(_format(context, end)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: busy ? null : onPickEnd,
            ),
            TextFormField(
              controller: reasonController,
              enabled: !busy,
              maxLength: 1000,
              maxLines: 3,
              decoration: InputDecoration(labelText: context.tr('Reason')),
              validator: (text) => (text?.trim().length ?? 0) < 5
                  ? context.tr('Please add a reason of at least 5 characters.')
                  : null,
            ),
            if (error != null)
              Text(
                context.tr(error!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ),
  );
}
