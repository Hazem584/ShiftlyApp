import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/widgets/attendance_period_fields.dart';

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
    if ((!_start.isAtSameMomentAs(widget.request.requestedIn) ||
            !_end.isAtSameMomentAs(widget.request.requestedOut)) &&
        _note.text.trim().length < 3) {
      setState(
        () =>
            _error = 'Explain why the approved times differ from the request.',
      );
      return;
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
      title: Text(context.tr('Approve attendance and hours')),
      scrollable: true,
      content: SizedBox(
        width: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.request.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (widget.request.isMissingAttendance)
              Text(
                '${widget.request.shiftName} · ${widget.request.operationalDate}',
              ),
            Text(widget.request.reason),
            const SizedBox(height: 12),
            Text(
              context.tr(
                'Choose the period to count. Only the approved hours will be recorded.',
              ),
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
            TextField(
              controller: _note,
              enabled: !_busy,
              maxLines: 3,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: context.tr('Review note'),
                helperText: context.tr(
                  'Required when changing the requested times.',
                ),
              ),
            ),
            if (_error != null)
              Text(
                context.tr(_error!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
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
