part of '../../employee_leave_requests_panel.dart';

class _EmployeeLeaveCard extends StatelessWidget {
  const _EmployeeLeaveCard({
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
        title: const Text('Cancel leave request?'),
        content: const Text(
          'This request will no longer be available for manager approval.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep request'),
          ),
          FilledButton(
            key: const Key('confirm-cancel-leave'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel request'),
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
                leaveTypeLabel(request.type),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            LeaveStatusBadge(status: request.status),
          ],
        ),
        const SizedBox(height: 10),
        LeaveDetailRow(
          icon: Icons.calendar_today_outlined,
          text:
              '${WorkspaceTime.dateTime(request.startsAt, timezone, locale: Localizations.localeOf(context).toString())} – ${WorkspaceTime.dateTime(request.endsAt, timezone, locale: Localizations.localeOf(context).toString())}',
        ),
        const SizedBox(height: 7),
        LeaveDetailRow(icon: Icons.notes_rounded, text: request.reason),
        if (request.rejectionReason?.isNotEmpty == true) ...[
          const SizedBox(height: 7),
          LeaveDetailRow(
            icon: Icons.info_outline,
            text: 'Rejection reason: ${request.rejectionReason}',
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
              label: const Text('Cancel request'),
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
