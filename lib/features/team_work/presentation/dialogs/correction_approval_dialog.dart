import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/attendance/presentation/refresh_attendance_views.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_dialog.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/edit_attendance_day_submit.dart';
import 'package:shiftly/features/team_work/presentation/widgets/correction_approval_body.dart';

class CorrectionApprovalDialog extends StatefulWidget {
  const CorrectionApprovalDialog({
    super.key,
    required this.request,
    required this.repository,
    required this.workspaceId,
    required this.timezone,
  });
  final CorrectionRequest request;
  final TeamWorkRepository repository;
  final String workspaceId, timezone;
  @override
  State<CorrectionApprovalDialog> createState() =>
      _CorrectionApprovalDialogState();
}

class _CorrectionApprovalDialogState extends State<CorrectionApprovalDialog> {
  late DateTime _start = widget.request.requestedIn;
  late DateTime _end = widget.request.requestedOut;
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    if (_busy) return;
    final periodErr = validateCompletedAttendancePeriod(_start, _end);
    if (periodErr != null) return setState(() => _error = periodErr);
    if ((!_start.isAtSameMomentAs(widget.request.requestedIn) ||
            !_end.isAtSameMomentAs(widget.request.requestedOut)) &&
        _note.text.trim().length < 3) {
      return setState(
        () =>
            _error = 'Explain why the approved times differ from the request.',
      );
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.reviewCorrection(
        widget.workspaceId,
        widget.request.id,
        approve: true,
        clockIn: _start,
        clockOut: _end,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      if (mounted) {
        refreshAttendanceViews(context);
        Navigator.pop(context, true);
      }
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
    child: ManagerDialog(
      title: Text(context.tr('Approve attendance and hours')),
      scrollable: true,
      content: CorrectionApprovalBody(
        request: widget.request,
        timezone: widget.timezone,
        start: _start,
        end: _end,
        busy: _busy,
        noteController: _note,
        error: _error,
        onStartChanged: (v) => setState(() => _start = v),
        onEndChanged: (v) => setState(() => _end = v),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          key: const Key('confirm-correction-approval'),
          onPressed: _busy ? null : _approve,
          child: Text(
            context.tr(_busy ? 'Saving…' : 'Approve attendance and hours'),
          ),
        ),
      ],
    ),
  );
}
