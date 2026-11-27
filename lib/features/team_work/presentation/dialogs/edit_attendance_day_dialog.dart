import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_calendar_repository.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_form_surface.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/edit_attendance_day_submit.dart';
import 'package:shiftly/features/team_work/presentation/widgets/edit_attendance_day_form.dart';

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
    final periodError = validateCompletedAttendancePeriod(_start, _end);
    if (periodError != null) return setState(() => _error = periodError);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await submitAttendanceDayEdit(
        repository: widget.repository,
        workspaceId: widget.workspaceId,
        manager: widget.manager,
        entry: widget.entry,
        date: widget.date,
        reasonKind: _kind,
        start: _start,
        end: _end,
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
      title: Text(
        context.tr(
          widget.manager ? 'Edit attendance' : 'Request attendance correction',
        ),
      ),
      scrollable: true,
      content: EditAttendanceDayForm(
        formKey: _form,
        employeeName: widget.entry.employee.displayName,
        manager: widget.manager,
        kind: _kind,
        start: _start,
        end: _end,
        scheduledStart:
            widget.entry.attendance?.scheduledStartAt ??
            widget.entry.shift?.startsAt,
        scheduledEnd:
            widget.entry.attendance?.scheduledEndAt ??
            widget.entry.shift?.endsAt,
        timezone: widget.timezone,
        busy: _busy,
        reasonController: _reason,
        error: _error,
        onKindChanged: (value) => setState(() => _kind = value),
        onStartChanged: (value) => setState(() => _start = value),
        onEndChanged: (value) => setState(() => _end = value),
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
