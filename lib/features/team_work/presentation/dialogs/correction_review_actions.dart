import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/correction_approval_dialog.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/review_note_dialog.dart';

Future<void> handleCorrectionDialogReview({
  required BuildContext context,
  required bool Function() isMounted,
  required bool approve,
  required Future<CorrectionRequest> requestFuture,
  required TeamWorkRepository repository,
  required String workspaceId,
  required String requestId,
  required String timezone,
  required void Function() onStartBusy,
  required void Function(String) onError,
}) async {
  if (approve) {
    final request = await requestFuture;
    if (!context.mounted || !isMounted()) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => CorrectionApprovalDialog(
        request: request,
        repository: repository,
        workspaceId: workspaceId,
        timezone: timezone,
      ),
    );
    if (saved == true && context.mounted && isMounted()) {
      Navigator.pop(context, true);
    }
    return;
  }
  final note = await requestReviewNote(context);
  if (note == null || !isMounted()) return;
  onStartBusy();
  try {
    await repository.reviewCorrection(
      workspaceId,
      requestId,
      approve: false,
      note: note,
    );
    if (context.mounted && isMounted()) Navigator.pop(context, true);
  } catch (error) {
    if (isMounted()) onError(ApiErrorParser.parse(error).message);
  }
}
