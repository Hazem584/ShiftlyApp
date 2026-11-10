import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_calendar_repository.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/widgets/attendance_period_fields.dart';

class EditAttendanceDayDialog extends StatefulWidget {
  const EditAttendanceDayDialog({
    required this.entry,
    required this.date,
    required this.workspaceId,
    required this.timezone,
    required this.manager,
    required this.repository,
    super.key,
  });
  final AttendanceCalendarEntry entry;
  final DateTime date;
  final String workspaceId, timezone;
  final bool manager;
  final TeamWorkRepository repository;
  @override
  State<EditAttendanceDayDialog> createState() =>
      _EditAttendanceDayDialogState();
}

class _EditAttendanceDayDialogState extends State<EditAttendanceDayDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  late DateTime _start =
      widget.entry.attendance?.clockInAt ?? widget.entry.shift!.startsAt;
  late DateTime _end =
      widget.entry.attendance?.clockOutAt ?? widget.entry.shift!.endsAt;
  String _kind = 'FORGOT_TO_RECORD';
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    final duration = _end.difference(_start);
    if (duration.inMinutes < 1 ||
        duration > const Duration(hours: 24) ||
        _end.isAfter(DateTime.now())) {
      setState(
        () => _error =
            'Choose a completed period of up to 24 hours, ending before now.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final entry = widget.entry, shift = entry.shift;
      final date = WorkspaceTime.localDateKey(
        year: widget.date.year,
        month: widget.date.month,
        day: widget.date.day,
      );
      final legacyId =
          shift != null &&
              shift.assignmentId == null &&
              shift.extraAuthorizationId == null
          ? shift.id
          : null;
      if (widget.manager) {
        await widget.repository.recordAttendanceDay(
          widget.workspaceId,
          employeeMembershipId: entry.employeeMembershipId,
          attendanceId: entry.attendance?.id,
          assignmentId: shift?.assignmentId,
          extraAuthorizationId: shift?.extraAuthorizationId,
          shiftId: legacyId,
          operationalDate: date,
          reasonKind: _kind,
          clockIn: _start,
          clockOut: _end,
          reason: _reason.text,
        );
      } else if (entry.attendance != null) {
        await widget.repository.requestCorrection(
          widget.workspaceId,
          attendanceId: entry.attendance!.id,
          clockIn: _start,
          clockOut: _end,
          reason: _reason.text,
        );
      } else {
        await widget.repository.requestMissedAttendance(
          widget.workspaceId,
          assignmentId: shift?.assignmentId,
          extraAuthorizationId: shift?.extraAuthorizationId,
          shiftId: legacyId,
          operationalDate: date,
          reasonKind: _kind,
          clockIn: _start,
          clockOut: _end,
          reason: _reason.text,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = ApiErrorParser.parse(error).message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(
        context.tr(
          widget.manager ? 'Edit attendance' : 'Request attendance correction',
        ),
      ),
      scrollable: true,
      content: SizedBox(
        width: 460,
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.entry.employee.displayName),
              Text(
                context.tr(
                  widget.manager
                      ? 'Changes are applied immediately and recorded in the audit history.'
                      : 'Your attendance changes only after your manager approves this request.',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _kind,
                isExpanded: true,
                decoration: InputDecoration(labelText: context.tr('Reason')),
                items: [
                  for (final (value, label) in const [
                    (
                      'FORGOT_TO_RECORD',
                      'I attended but forgot to record attendance',
                    ),
                    (
                      'EXCEPTION',
                      'I have an exception or special circumstance',
                    ),
                    ('OTHER', 'Other reason'),
                  ])
                    DropdownMenuItem(
                      value: value,
                      child: Text(context.tr(label), maxLines: 2),
                    ),
                ],
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _kind = value!),
              ),
              AttendancePeriodFields(
                start: _start,
                end: _end,
                timezone: widget.timezone,
                busy: _busy,
                onStart: (value) => setState(() => _start = value),
                onEnd: (value) => setState(() => _end = value),
              ),
              Text(
                context.tr(
                  'Overtime is calculated from the approved times and your break policy.',
                ),
              ),
              TextFormField(
                controller: _reason,
                enabled: !_busy,
                minLines: 2,
                maxLines: 4,
                maxLength: 1000,
                decoration: InputDecoration(
                  labelText: context.tr('Explain what happened'),
                ),
                validator: (value) => (value?.trim().length ?? 0) < 5
                    ? context.tr(
                        'Please add a reason of at least 5 characters.',
                      )
                    : null,
              ),
              if (_error != null)
                Text(
                  context.tr(_error!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          key: const Key('save-attendance-day'),
          onPressed: _busy ? null : _save,
          child: Text(
            context.tr(
              _busy
                  ? 'Saving…'
                  : widget.manager
                  ? 'Save attendance'
                  : 'Send request',
            ),
          ),
        ),
      ],
    ),
  );
}
