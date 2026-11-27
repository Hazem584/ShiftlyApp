import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/dialogs/leave_request_rejection_dialog.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_details_dialog.dart';

Future<void> decideLeaveRequest(
  BuildContext context,
  LeaveRequestRecord request,
  LeaveReviewDecision decision,
) async {
  String? rejectionReason;
  if (decision == LeaveReviewDecision.rejected) {
    rejectionReason = await showDialog<String>(
      context: context,
      builder: (_) => LeaveRequestRejectionDialog(
        employeeName: request.employee.displayName,
      ),
    );
    if (rejectionReason == null || !context.mounted) return;
  }
  final result = await context.read<LeaveRequestsCubit>().review(
    request.id,
    decision,
    rejectionReason: rejectionReason,
  );
  if (!context.mounted || result == LeaveMutationResult.stale) return;
  if (result == LeaveMutationResult.success) {
    ToastService.success(
      context,
      message: decision == LeaveReviewDecision.approved
          ? 'Request approved'
          : 'Request rejected',
    );
  } else if (result == LeaveMutationResult.failure) {
    ToastService.error(
      context,
      message:
          context.read<LeaveRequestsCubit>().state.failure?.message ??
          'Could not update request',
    );
  }
}

Future<void> openLeaveRequestDetails(
  BuildContext context,
  String requestId,
  String timezone,
) async {
  final record = await context.read<LeaveRequestsCubit>().loadDetails(
    requestId,
  );
  if (record == null || !context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (_) =>
        LeaveRequestDetailsDialog(request: record, timezone: timezone),
  );
}

Widget buildLeaveRequestActionButtons(
  BuildContext context,
  LeaveRequestRecord request,
  bool updating,
) => LayoutBuilder(
  builder: (context, constraints) {
    final compact = constraints.maxWidth < 360;
    final reject = OutlinedButton.icon(
      key: Key('reject-${request.id}'),
      onPressed: updating
          ? null
          : () => decideLeaveRequest(
              context,
              request,
              LeaveReviewDecision.rejected,
            ),
      icon: const Icon(Icons.close_rounded, size: 17),
      label: Text(context.tr('Reject')),
    );
    final approve = FilledButton.icon(
      key: Key('approve-${request.id}'),
      onPressed: updating
          ? null
          : () => decideLeaveRequest(
              context,
              request,
              LeaveReviewDecision.approved,
            ),
      icon: updating
          ? const SizedBox.square(
              dimension: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.check_rounded, size: 17),
      label: Text(context.tr('Approve')),
    );
    return compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [reject, const SizedBox(height: 8), approve],
          )
        : Row(
            children: [
              Expanded(child: reject),
              const SizedBox(width: 9),
              Expanded(child: approve),
            ],
          );
  },
);
