import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_form_surface.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/eligible_shift_occurrence.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/widgets/missed_attendance_form_body.dart';

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
        !_start.isBefore(widget.entry.scheduledEndAt) ||
        !_end.isAfter(widget.entry.scheduledStartAt)) {
      return setState(
        () => _error = 'Choose a completed period within this shift.',
      );
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
    child: EmployeeFormSurface(
      title: Text(context.tr('Review missing attendance')),
      scrollable: true,
      content: MissedAttendanceFormBody(
        formKey: _form,
        entry: widget.entry,
        timezone: widget.timezone,
        kind: _kind,
        start: _start,
        end: _end,
        busy: _busy,
        reasonController: _reason,
        error: _error,
        onKindChanged: (v) => setState(() => _kind = v),
        onStartChanged: (v) => setState(() => _start = v),
        onEndChanged: (v) => setState(() => _end = v),
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
