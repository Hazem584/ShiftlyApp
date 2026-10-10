import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/utils/leave_request_display_formatters.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_detail_row.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_details_dialog.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_display.dart';

class EmployeeLeaveCard extends StatelessWidget {
  const EmployeeLeaveCard({
    super.key,
    required this.request,
    required this.timezone,
    required this.cancelling,
  });
  final LeaveRequestRecord request;
  final String timezone;
  final bool cancelling;

  Future<void> _cancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Cancel leave request?')),
        content: Text(
          context.tr(
            'This request will no longer be available for manager approval.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('Keep request')),
          ),
          FilledButton(
            key: const Key('confirm-cancel-leave'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('Cancel request')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final cubit = context.read<EmployeeLeaveRequestsCubit>();
    final result = await cubit.cancel(request.id);
    if (!context.mounted || result == LeaveMutationResult.stale) return;
    if (result == LeaveMutationResult.success) {
      ToastService.success(context, message: 'Leave request cancelled');
    } else if (result == LeaveMutationResult.failure) {
      ToastService.error(
        context,
        message: cubit.state.failure?.message ?? 'Could not cancel request',
      );
    }
  }

  @override
  Widget build(BuildContext context) => SurfaceCard(
    key: Key('employee-request-${request.id}'),
    onTap: () => _openDetails(context),
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr(leaveTypeLabel(request.type)),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            LeaveStatusBadge(status: request.status),
          ],
        ),
        const SizedBox(height: 10),
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
        if (request.rejectionReason?.isNotEmpty == true) ...[
          const SizedBox(height: 7),
          LeaveDetailRow(
            icon: Icons.info_outline,
            text: context.tr('Rejection reason: {value1}', {
              'value1': (request.rejectionReason).toString(),
            }),
          ),
        ],
        if (request.canCancel) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              key: Key('cancel-${request.id}'),
              onPressed: cancelling ? null : () => _cancel(context),
              icon: cancelling
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cancel_outlined),
              label: Text(context.tr('Cancel request')),
            ),
          ),
        ],
      ],
    ),
  );

  Future<void> _openDetails(BuildContext context) async {
    final record = await context.read<EmployeeLeaveRequestsCubit>().loadDetails(
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
