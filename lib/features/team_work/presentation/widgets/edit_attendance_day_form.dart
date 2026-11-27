import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/team_work/presentation/widgets/attendance_period_fields.dart';
import 'package:shiftly/features/team_work/presentation/widgets/attendance_reason_dropdown.dart';

class EditAttendanceDayForm extends StatelessWidget {
  const EditAttendanceDayForm({
    super.key,
    required this.formKey,
    required this.employeeName,
    required this.manager,
    required this.kind,
    required this.start,
    required this.end,
    required this.timezone,
    required this.busy,
    required this.reasonController,
    required this.error,
    required this.onKindChanged,
    required this.onStartChanged,
    required this.onEndChanged,
  });
  final GlobalKey<FormState> formKey;
  final String employeeName, kind, timezone;
  final bool manager, busy;
  final DateTime start, end;
  final TextEditingController reasonController;
  final String? error;
  final ValueChanged<String> onKindChanged;
  final ValueChanged<DateTime> onStartChanged, onEndChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 460,
    child: Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(employeeName),
          Text(
            context.tr(
              manager
                  ? 'Changes are applied immediately and recorded in the audit history.'
                  : 'Your attendance changes only after your manager approves this request.',
            ),
          ),
          const SizedBox(height: 12),
          AttendanceReasonDropdown(
            value: kind,
            label: 'Reason',
            busy: busy,
            onChanged: onKindChanged,
          ),
          AttendancePeriodFields(
            start: start,
            end: end,
            timezone: timezone,
            busy: busy,
            onStart: onStartChanged,
            onEnd: onEndChanged,
          ),
          Text(
            context.tr(
              'Overtime is calculated from the approved times and your break policy.',
            ),
          ),
          TextFormField(
            controller: reasonController,
            enabled: !busy,
            minLines: 2,
            maxLines: 4,
            maxLength: 1000,
            decoration: InputDecoration(
              labelText: context.tr('Explain what happened'),
            ),
            validator: (value) => (value?.trim().length ?? 0) < 5
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
  );
}
