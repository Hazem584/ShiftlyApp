import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/correction_approval_dialog.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/review_note_dialog.dart';
import 'package:shiftly/features/team_work/presentation/widgets/correction_request_card.dart';

class CorrectionReviewDialog extends StatefulWidget {
  const CorrectionReviewDialog({
    super.key,
    required this.repository,
    required this.workspaceId,
    required this.requestId,
    required this.timezone,
  });
  final TeamWorkRepository repository;
  final String workspaceId, requestId, timezone;
  @override
  State<CorrectionReviewDialog> createState() => _CorrectionReviewDialogState();
}

class _CorrectionReviewDialogState extends State<CorrectionReviewDialog> {
  late final _request = widget.repository.correction(
    widget.workspaceId,
    widget.requestId,
  );
  bool _busy = false;
  String? _error;
  Future<void> _review(bool approve) async {
    if (_busy) return;
    if (approve) {
      final request = await _request;
      if (!mounted) return;
      final saved = await showDialog<bool>(
        context: context,
        builder: (_) => CorrectionApprovalDialog(
          request: request,
          repository: widget.repository,
          workspaceId: widget.workspaceId,
          timezone: widget.timezone,
        ),
      );
      if (saved == true && mounted) Navigator.pop(context, true);
      return;
    }
    final note = approve ? null : await requestReviewNote(context);
    if (!approve && note == null || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.reviewCorrection(
        widget.workspaceId,
        widget.requestId,
        approve: approve,
        note: note,
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
      title: Text(context.tr('Review correction')),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<CorrectionRequest>(
                future: _request,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      context.tr(ApiErrorParser.parse(snapshot.error!).message),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return CorrectionRequestCard(
                    request: snapshot.data!,
                    timezone: widget.timezone,
                    busy: _busy,
                    onApprove: () => _review(true),
                    onDecline: () => _review(false),
                  );
                },
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
          child: Text(context.tr('Close')),
        ),
      ],
    ),
  );
}
