import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/dialogs/leave_request_rejection_dialog.dart';
import 'package:shiftly/features/attendance/presentation/utils/leave_request_card_formatters.dart';
import 'package:shiftly/features/attendance/presentation/utils/leave_request_display_formatters.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_detail_row.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_details_dialog.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_display.dart';

class LeaveRequestCard extends StatelessWidget {
  const LeaveRequestCard({
    required this.request,
    required this.updating,
    required this.timezone,
    super.key,
  });
  final LeaveRequestRecord request;
  final bool updating;
  final String timezone;

  Future<void> _decide(
    BuildContext context,
    LeaveReviewDecision decision,
  ) async {
    String? rejectionReason;
    if (decision == LeaveReviewDecision.rejected) {
      rejectionReason = await _rejectionReason(context);
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

  Future<String?> _rejectionReason(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (_) => LeaveRequestRejectionDialog(
        employeeName: request.employee.displayName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = request.canReview;
    return SurfaceCard(
      key: Key('request-${request.id}'),
      onTap: () => _openDetails(context),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppPalette.of(context).selected,
                foregroundColor: AppPalette.of(context).ink,
                child: Text(
                  leaveRequestCardInitials(request.employee.displayName),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.employee.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      context.tr(leaveTypeLabel(request.type)),
                      style: TextStyle(
                        color: AppPalette.of(context).textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              LeaveStatusBadge(status: request.status),
            ],
          ),
          const SizedBox(height: 13),
          LeaveDetailRow(
            icon: Icons.calendar_today_outlined,
            text: context.tr('{value1} – {value2}', {
              'value1': (WorkspaceTime.dateTime(
                request.startsAt,
                timezone,
                locale: Localizations.localeOf(context).toString(),
              )).toString(),
              'value2': (WorkspaceTime.dateTime(
                request.endsAt,
                timezone,
                locale: Localizations.localeOf(context).toString(),
              )).toString(),
            }),
          ),
          const SizedBox(height: 7),
          LeaveDetailRow(icon: Icons.notes_rounded, text: request.reason),
          const SizedBox(height: 7),
          LeaveDetailRow(
            icon: Icons.schedule_rounded,
            text: context.tr('Submitted {value1}', {
              'value1': (WorkspaceTime.dateTime(
                request.createdAt,
                timezone,
                locale: Localizations.localeOf(context).toString(),
              )).toString(),
            }),
          ),
          if (request.rejectionReason?.isNotEmpty == true) ...[
            const SizedBox(height: 7),
            LeaveDetailRow(
              icon: Icons.info_outline,
              text: context.tr('Reason: {value1}', {
                'value1': (request.rejectionReason).toString(),
              }),
            ),
          ],
          if (pending) ...[
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 360;
                final reject = OutlinedButton.icon(
                  key: Key('reject-${request.id}'),
                  onPressed: updating
                      ? null
                      : () => _decide(context, LeaveReviewDecision.rejected),
                  icon: const Icon(Icons.close_rounded, size: 17),
                  label: Text(context.tr('Reject')),
                );
                final approve = FilledButton.icon(
                  key: Key('approve-${request.id}'),
                  onPressed: updating
                      ? null
                      : () => _decide(context, LeaveReviewDecision.approved),
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
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openDetails(BuildContext context) async {
    final record = await context.read<LeaveRequestsCubit>().loadDetails(
      request.id,
    );
    if (record == null || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) =>
          LeaveRequestDetailsDialog(request: record, timezone: timezone),
    );
  }
}
