import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_calendar_entry.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_controls_repository.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_dialog.dart';

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
      final entry = widget.entry;
      if (entry == null) {
        await widget.repository.decideMonth(
          workspaceId: widget.workspaceId,
          year: widget.year,
          month: widget.month,
          revision: widget.revision,
          close: widget.closeMonth,
          reason: _reason.text.trim(),
        );
      } else {
        final d = widget.date!;
        await widget.repository.decideDay(
          workspaceId: widget.workspaceId,
          employeeMembershipId: entry.employeeMembershipId,
          date:
              '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
          status: _status,
          reason: _reason.text.trim(),
          revision: widget.revision,
        );
      }
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
            children: [
              Text(
                widget.date?.toIso8601String().split('T').first ??
                    '${widget.year}-${widget.month.toString().padLeft(2, '0')}',
              ),
              const SizedBox(height: 8),
              if (widget.entry != null) ...[
                Text(widget.entry!.employee.displayName),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.tr('Attendance status'),
                  ),
                  items: const ['AUTO', 'PRESENT', 'LATE', 'ABSENT', 'LEAVE']
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(context.tr(attendanceDecisionLabel(s))),
                        ),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (s) => setState(() => _status = s!),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr(
                    'The day status changes; recorded clock times remain in the audit history.',
                  ),
                ),
              ] else
                Text(
                  context.tr(
                    widget.closeMonth
                        ? 'Review the monthly totals before closing. Changes require reopening the month with a reason.'
                        : 'Reopening allows attendance changes. The previous approval remains in the audit history.',
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reason,
                enabled: !_saving,
                minLines: 2,
                maxLines: 4,
                maxLength: 1000,
                decoration: InputDecoration(labelText: context.tr('Reason')),
                validator: (v) => (v?.trim().length ?? 0) < 3
                    ? context.tr('Enter a reason of at least 3 characters.')
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

String attendanceDecisionLabel(String status) => switch (status) {
  'PRESENT' => 'Present',
  'LATE' => 'Late',
  'ABSENT' => 'Absent',
  'LEAVE' => 'Leave',
  _ => 'Use recorded attendance',
};
