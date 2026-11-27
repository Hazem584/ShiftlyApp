import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/team_work/presentation/widgets/attendance_period_fields.dart';
import 'package:shiftly/features/team_work/presentation/widgets/attendance_reason_dropdown.dart';
import 'package:shiftly/features/team_work/presentation/widgets/manager_overtime_adjuster.dart';

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
    this.scheduledStart,
    this.scheduledEnd,
  });
  final GlobalKey<FormState> formKey;
  final String employeeName, kind, timezone;
  final bool manager, busy;
  final DateTime start, end;
  final DateTime? scheduledStart, scheduledEnd;
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
          Text(employeeName, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            context.tr(
              manager
                  ? 'Set the actual clock-in, clock-out, and overtime directly.'
                  : 'Your attendance changes only after your manager approves this request.',
            ),
          ),
          const SizedBox(height: 12),
          if (!manager)
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
          if (manager)
            ManagerOvertimeAdjuster(
              start: start,
              end: end,
              scheduledStart: scheduledStart,
              scheduledEnd: scheduledEnd,
              busy: busy,
              onEndChanged: onEndChanged,
            )
          else ...[
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
          ],
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                context.tr(error!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    ),
  );
}
