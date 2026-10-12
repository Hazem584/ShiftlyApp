import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/eligible_shift_occurrence.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/widgets/attendance_period_fields.dart';

class MissedAttendanceRequestDialog extends StatefulWidget {
  const MissedAttendanceRequestDialog({
    super.key,
    required this.entry,
    required this.workspaceId,
    required this.timezone,
    required this.repository,
  });
  final EligibleShiftOccurrence entry;
  final String workspaceId, timezone;
  final TeamWorkRepository repository;
  @override
  State<MissedAttendanceRequestDialog> createState() =>
      _MissedAttendanceRequestDialogState();
}

class _MissedAttendanceRequestDialogState
    extends State<MissedAttendanceRequestDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  late DateTime _start = widget.entry.scheduledStartAt;
  late DateTime _end = widget.entry.scheduledEndAt;
  String _kind = 'FORGOT_TO_RECORD';
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    final duration = _end.difference(_start);
    if (duration.inMinutes < 1 ||
        duration > const Duration(hours: 24) ||
        _end.isAfter(DateTime.now()) ||
        _start.isBefore(widget.entry.scheduledStartAt) ||
        _end.isAfter(widget.entry.scheduledEndAt)) {
      setState(() => _error = 'Choose a completed period within this shift.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.requestMissedAttendance(
        widget.workspaceId,
        assignmentId: widget.entry.assignmentId,
        extraAuthorizationId: widget.entry.extraAuthorizationId,
        operationalDate: widget.entry.operationalDate,
        reasonKind: _kind,
        clockIn: _start,
        clockOut: _end,
        reason: _reason.text,
      );
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
      title: Text(context.tr('Review missing attendance')),
      scrollable: true,
      content: SizedBox(
        width: 460,
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.entry.template.name} · ${widget.entry.operationalDate}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                context.tr(
                  'No attendance was recorded for this shift. Explain what happened and the period you want counted. Your manager may approve all or part of it, or decline.',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _kind,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.tr('Why was attendance not recorded?'),
                ),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _reason,
                enabled: !_busy,
                maxLines: 3,
                maxLength: 1000,
                decoration: InputDecoration(
                  labelText: context.tr('Explain what happened'),
                ),
                validator: (text) => (text?.trim().length ?? 0) < 5
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
          key: const Key('send-missed-attendance-request'),
          onPressed: _busy ? null : _submit,
          child: Text(context.tr(_busy ? 'Saving…' : 'Send request')),
        ),
      ],
    ),
  );
}
