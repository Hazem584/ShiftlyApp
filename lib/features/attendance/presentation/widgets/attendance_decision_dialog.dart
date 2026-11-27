import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_calendar_entry.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_controls_repository.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_decision_dialog_helpers.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_dialog.dart';

export 'attendance_decision_dialog_helpers.dart' show attendanceDecisionLabel;

class AttendanceDecisionDialog extends StatefulWidget {
  const AttendanceDecisionDialog({
    required this.repository,
    required this.workspaceId,
    required this.year,
    required this.month,
    required this.revision,
    this.entry,
    this.date,
    this.closeMonth = false,
    super.key,
  });
  final AttendanceControlsRepository repository;
  final String workspaceId;
  final int year, month, revision;
  final AttendanceCalendarEntry? entry;
  final DateTime? date;
  final bool closeMonth;
  @override
  State<AttendanceDecisionDialog> createState() =>
      _AttendanceDecisionDialogState();
}

class _AttendanceDecisionDialogState extends State<AttendanceDecisionDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  String _status = 'AUTO';
  String? _error;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    if (entry?.decisionReason != null) {
      _status = entry!.status.name.toUpperCase();
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await performAttendanceDecisionSave(
        repository: widget.repository,
        workspaceId: widget.workspaceId,
        year: widget.year,
        month: widget.month,
        revision: widget.revision,
        closeMonth: widget.closeMonth,
        entry: widget.entry,
        date: widget.date,
        status: _status,
        reason: _reason.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e is ApiException
              ? e.message
              : 'Could not save attendance decision. Refresh and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.entry != null
        ? 'Change attendance status'
        : widget.closeMonth
        ? 'Approve and close month'
        : 'Reopen attendance month';
    return ManagerDialog(
      title: Text(context.tr(title)),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: buildAttendanceDecisionContent(
              context: context,
              entry: widget.entry,
              date: widget.date,
              year: widget.year,
              month: widget.month,
              closeMonth: widget.closeMonth,
              status: _status,
              saving: _saving,
              onStatusChanged: (s) => setState(() => _status = s!),
              reasonController: _reason,
              error: _error,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(context.tr(_saving ? 'Saving…' : 'Save decision')),
        ),
      ],
    );
  }
}
