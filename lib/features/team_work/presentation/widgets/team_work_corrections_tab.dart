import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/cubit/work_feed_cubit.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/correction_approval_dialog.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/review_note_dialog.dart';
import 'package:shiftly/features/team_work/presentation/widgets/correction_request_card.dart';
import 'package:shiftly/features/team_work/presentation/widgets/work_feed_view.dart';

Future<void> reviewTeamWorkCorrection({
  required BuildContext context,
  required bool Function() isMounted,
  required CorrectionRequest request,
  required bool approve,
  required TeamWorkRepository repository,
  required String workspaceId,
  required String timezone,
  required WorkFeedCubit<CorrectionRequest> corrections,
  required WorkFeedCubit<WorkTask> tasks,
}) async {
  if (approve) {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => CorrectionApprovalDialog(
        request: request,
        repository: repository,
        workspaceId: workspaceId,
        timezone: timezone,
      ),
    );
    if (saved == true && isMounted()) {
      corrections.load();
      tasks.load();
    }
    return;
  }
  final note = await requestReviewNote(context);
  if (note == null) return;
  final saved = await corrections.mutate(
    request.id,
    () => repository.reviewCorrection(
      workspaceId,
      request.id,
      approve: false,
      note: note,
    ),
  );
  if (saved) tasks.load();
}

class TeamWorkCorrectionsTab extends StatelessWidget {
  const TeamWorkCorrectionsTab({
    super.key,
    required this.cubit,
    required this.status,
    required this.timezone,
    required this.manager,
    required this.onStatusChanged,
    required this.onReview,
  });
  final WorkFeedCubit<CorrectionRequest> cubit;
  final String? status;
  final String timezone;
  final bool manager;
  final ValueChanged<String?> onStatusChanged;
  final void Function(CorrectionRequest, bool) onReview;

  @override
  Widget build(BuildContext context) => WorkFeedView(
    cubit: cubit,
    header: Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (value, label) in <(String?, String)>[
            (null, 'All'),
            ('PENDING', 'Pending review'),
            ('APPROVED', 'Approved'),
            ('REJECTED', 'Declined'),
          ])
            ChoiceChip(
              label: Text(context.tr(label)),
              selected: status == value,
              onSelected: (_) => onStatusChanged(value),
            ),
        ],
      ),
    ),
    itemBuilder: (_, request, busy) => CorrectionRequestCard(
      request: request,
      timezone: timezone,
      busy: busy,
      onApprove: manager ? () => onReview(request, true) : null,
      onDecline: manager ? () => onReview(request, false) : null,
    ),
  );
}
