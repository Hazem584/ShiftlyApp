import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/eligible_shift_occurrence.dart';
import 'package:shiftly/features/team_work/presentation/widgets/attendance_period_fields.dart';
import 'package:shiftly/features/team_work/presentation/widgets/attendance_reason_dropdown.dart';

class MissedAttendanceFormBody extends StatelessWidget {
  const MissedAttendanceFormBody({
    super.key,
    required this.formKey,
    required this.entry,
    required this.timezone,
    required this.kind,
    required this.start,
    required this.end,
    required this.busy,
    required this.reasonController,
    required this.error,
    required this.onKindChanged,
    required this.onStartChanged,
    required this.onEndChanged,
  });
  final GlobalKey<FormState> formKey;
  final EligibleShiftOccurrence entry;
  final String timezone, kind;
  final DateTime start, end;
  final bool busy;
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${entry.template.name} · ${entry.operationalDate}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              'No attendance was recorded for this shift. Explain what happened and the period you want counted. Your manager may approve all or part of it, or decline.',
            ),
          ),
          const SizedBox(height: 16),
          AttendanceReasonDropdown(
            value: kind,
            label: 'Why was attendance not recorded?',
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
          const SizedBox(height: 12),
          TextFormField(
            controller: reasonController,
            enabled: !busy,
            maxLines: 3,
            maxLength: 1000,
            decoration: InputDecoration(
              labelText: context.tr('Explain what happened'),
            ),
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
  );
}
