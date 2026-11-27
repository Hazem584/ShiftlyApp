import 'package:flutter/material.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_form_surface.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/widgets/correction_request_form_body.dart';

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

  Future<void> _pick(bool start) async {
    final utc = await pickCorrectionWallTimeToUtc(
      context,
      start ? _start : _end,
      widget.timezone,
    );
    if (utc != null && mounted) {
      setState(() => start ? _start = utc : _end = utc);
    }
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    final duration = _end.difference(_start);
    if (duration <= Duration.zero ||
        duration > const Duration(hours: 24) ||
        _end.isAfter(DateTime.now())) {
      return setState(
        () => _error =
            'Choose a completed period of up to 24 hours, ending before now.',
      );
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
    child: EmployeeFormSurface(
      title: Text(context.tr('Request attendance correction')),
      content: CorrectionRequestFormBody(
        formKey: _form,
        record: widget.record,
        timezone: widget.timezone,
        start: _start,
        end: _end,
        busy: _busy,
        reasonController: _reason,
        error: _error,
        onPickStart: () => _pick(true),
        onPickEnd: () => _pick(false),
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
