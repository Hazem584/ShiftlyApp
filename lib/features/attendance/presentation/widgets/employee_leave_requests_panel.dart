import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_display.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_details_dialog.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_form_dialog.dart';

class EmployeeLeaveRequestsPanel extends StatelessWidget {
  const EmployeeLeaveRequestsPanel({required this.timezone, super.key});
  final String timezone;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<EmployeeLeaveRequestsCubit, EmployeeLeaveRequestsState>(
    builder: (context, state) {
      if (state.initialLoading) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(),
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: () =>
            context.read<EmployeeLeaveRequestsCubit>().load(refresh: true),
        child: ListView(
          key: const Key('employee-leave-request-list'),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'My leave requests',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton.icon(
                  key: const Key('request-leave'),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => BlocProvider.value(
                      value: context.read<EmployeeLeaveRequestsCubit>(),
                      child: LeaveRequestFormDialog(timezone: timezone),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Request leave'),
                ),
              ],
            ),
            if (state.failure != null) ...[
              const SizedBox(height: AppSpacing.s),
              Text(
                state.failure!.message,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            const SizedBox(height: AppSpacing.m),
            if (state.requests.isEmpty)
              EmptyState(
                icon: state.failure == null
                    ? Icons.event_note_outlined
                    : Icons.cloud_off_outlined,
                title: state.failure == null
                    ? 'No leave requests'
                    : 'Could not load requests',
                message:
                    state.failure?.message ??
                    'Requests you submit for this workspace will appear here.',
                action: state.failure == null
                    ? null
                    : FilledButton(
                        onPressed: context
                            .read<EmployeeLeaveRequestsCubit>()
                            .load,
                        child: const Text('Retry'),
                      ),
              )
            else
              for (final request in state.requests) ...[
                _EmployeeLeaveCard(
                  request: request,
                  timezone: timezone,
                  cancelling: state.cancellingIds.contains(request.id),
                ),
                const SizedBox(height: 10),
              ],
            if (state.hasMore)
              OutlinedButton(
                onPressed: state.loadingMore
                    ? null
                    : context.read<EmployeeLeaveRequestsCubit>().loadMore,
                child: state.loadingMore
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Load more'),
              ),
          ],
        ),
      );
    },
  );
}

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
              '${WorkspaceTime.dateTime(request.startsAt, timezone)} – ${WorkspaceTime.dateTime(request.endsAt, timezone)}',
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
