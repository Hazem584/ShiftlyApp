import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/presentation/widgets/attendance_period_fields.dart';

class CorrectionApprovalBody extends StatelessWidget {
  const CorrectionApprovalBody({
    super.key,
    required this.request,
    required this.timezone,
    required this.start,
    required this.end,
    required this.busy,
    required this.noteController,
    required this.error,
    required this.onStartChanged,
    required this.onEndChanged,
  });
  final CorrectionRequest request;
  final String timezone;
  final DateTime start, end;
  final bool busy;
  final TextEditingController noteController;
  final String? error;
  final ValueChanged<DateTime> onStartChanged, onEndChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 460,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(request.name, style: Theme.of(context).textTheme.titleMedium),
        if (request.isMissingAttendance)
          Text('${request.shiftName} · ${request.operationalDate}'),
        Text(request.reason),
        const SizedBox(height: 12),
        Text(
          context.tr(
            'Choose the period to count. Only the approved hours will be recorded.',
          ),
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
        TextField(
          controller: noteController,
          enabled: !busy,
          maxLines: 3,
          maxLength: 1000,
          decoration: InputDecoration(
            labelText: context.tr('Review note'),
            helperText: context.tr(
              'Required when changing the requested times.',
            ),
          ),
        ),
        if (error != null)
          Text(
            context.tr(error!),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    ),
  );
}
