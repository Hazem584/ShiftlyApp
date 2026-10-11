import 'package:flutter/material.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';

Future<bool?> showCorrectionRequest(
  BuildContext context,
  AttendanceRecordApi record,
  String timezone,
) => showDialog<bool>(
  context: context,
  builder: (_) => CorrectionRequestDialog(record: record, timezone: timezone),
);

class CorrectionRequestDialog extends StatefulWidget {
  const CorrectionRequestDialog({
    super.key,
    required this.record,
    required this.timezone,
  });
  final AttendanceRecordApi record;
  final String timezone;
  @override
  State<CorrectionRequestDialog> createState() =>
      _CorrectionRequestDialogState();
}

class _CorrectionRequestDialogState extends State<CorrectionRequestDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  late DateTime _start = widget.record.clockInAt;
  late DateTime _end = widget.record.clockOutAt!;
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  String _format(DateTime value) => WorkspaceTime.dateTime(
    value,
    widget.timezone,
    locale: Localizations.localeOf(context).toString(),
  );
  Future<void> _pick(bool start) async {
    final current = WorkspaceTime.inWorkspace(
      start ? _start : _end,
      widget.timezone,
    );
    final today = WorkspaceTime.inWorkspace(DateTime.now(), widget.timezone);
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(current.year - 1),
      lastDate: today,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (time == null || !mounted) return;
    final utc = WorkspaceTime.wallTimeToUtc(
      date: date,
      hour: time.hour,
      minute: time.minute,
      timezoneName: widget.timezone,
    );
    setState(() {
      if (start) {
        _start = utc;
      } else {
        _end = utc;
      }
    });
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    final duration = _end.difference(_start);
    if (duration <= Duration.zero ||
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
      await getIt<TeamWorkRepository>().requestCorrection(
        widget.record.workspaceId,
        attendanceId: widget.record.id,
        clockIn: _start,
        clockOut: _end,
        reason: _reason.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = ApiErrorParser.parse(error).message;
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(context.tr('Request attendance correction')),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(
                    'Your manager will review these times before they change.',
                  ),
                ),
                const SizedBox(height: 12),
                Text(context.tr('Original times')),
                Text(
                  '${_format(widget.record.clockInAt)}\n${_format(widget.record.clockOutAt!)}',
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.tr('Requested clock in')),
                  subtitle: Text(_format(_start)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _busy ? null : () => _pick(true),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.tr('Requested clock out')),
                  subtitle: Text(_format(_end)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _busy ? null : () => _pick(false),
                ),
                TextFormField(
                  controller: _reason,
                  enabled: !_busy,
                  maxLength: 1000,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: context.tr('Reason')),
                  validator: (text) => (text?.trim().length ?? 0) < 5
                      ? context.tr(
                          'Please add a reason of at least 5 characters.',
                        )
                      : null,
                ),
                if (_error != null)
                  Text(
                    context.tr(_error!),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(context.tr(_busy ? 'Saving…' : 'Send request')),
        ),
      ],
    ),
  );
}
