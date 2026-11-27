import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_dialog.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/correction_review_actions.dart';
import 'package:shiftly/features/team_work/presentation/widgets/correction_review_preview.dart';

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
    await handleCorrectionDialogReview(
      context: context,
      isMounted: () => mounted,
      approve: approve,
      requestFuture: _request,
      repository: widget.repository,
      workspaceId: widget.workspaceId,
      requestId: widget.requestId,
      timezone: widget.timezone,
      onStartBusy: () => setState(() {
        _busy = true;
        _error = null;
      }),
      onError: (msg) => setState(() {
        _busy = false;
        _error = msg;
      }),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: ManagerDialog(
      title: Text(context.tr('Review correction')),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CorrectionReviewPreview(
                request: _request,
                timezone: widget.timezone,
                busy: _busy,
                onApprove: () => _review(true),
                onDecline: () => _review(false),
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
