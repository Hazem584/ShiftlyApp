import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/confirm_action.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/utils/leave_request_display_formatters.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_display.dart';

import 'employee_page.dart';
import 'employee_tile.dart';

class EmployeeLeaveDetailsScreen extends StatefulWidget {
  const EmployeeLeaveDetailsScreen({
    required this.request,
    required this.timezone,
    super.key,
  });
  final LeaveRequestRecord request;
  final String timezone;
  @override
  State<EmployeeLeaveDetailsScreen> createState() =>
      _EmployeeLeaveDetailsScreenState();
}

class _EmployeeLeaveDetailsScreenState
    extends State<EmployeeLeaveDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<EmployeeLeaveRequestsCubit>().loadDetails(
          widget.request.id,
        );
      }
    });
  }

  Future<void> _cancel() async {
    final cubit = context.read<EmployeeLeaveRequestsCubit>();
    final ok = await confirmAction(
      context,
      title: 'Cancel leave request?',
      message: context.tr(
        'This request will no longer be available for manager approval.',
      ),
      action: 'Cancel request',
      actionKey: 'confirm-cancel-leave',
    );
    if (!ok || !mounted) return;
    final result = await cubit.cancel(widget.request.id);
    if (mounted && result == LeaveMutationResult.failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cubit.state.failure?.message ??
                context.tr('Could not cancel request'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<EmployeeLeaveRequestsCubit, EmployeeLeaveRequestsState>(
    builder: (context, state) {
      final request = state.selected?.id == widget.request.id
          ? state.selected!
          : state.requests
                    .where((r) => r.id == widget.request.id)
                    .firstOrNull ??
                widget.request;
      final busy = state.cancellingIds.contains(request.id);
      final locale = Localizations.localeOf(context).toString();
      String date(DateTime d) =>
          WorkspaceTime.dateTime(d, widget.timezone, locale: locale);
      final from = WorkspaceTime.inWorkspace(request.startsAt, widget.timezone),
          to = WorkspaceTime.inWorkspace(request.endsAt, widget.timezone);
      final days =
          DateTime.utc(
            to.year,
            to.month,
            to.day,
          ).difference(DateTime.utc(from.year, from.month, from.day)).inDays +
          1;
      return EmployeePage(
        title: 'Request details',
        footer: request.canCancel
            ? FilledButton(
                key: Key('cancel-${request.id}'),
                onPressed: busy ? null : _cancel,
                child: Text(context.tr(busy ? 'Saving…' : 'Cancel request')),
              )
            : null,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              '${context.tr(leaveTypeLabel(request.type))} · ${date(request.startsAt)} → ${date(request.endsAt)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                LeaveStatusBadge(status: request.status),
                Chip(
                  label: Text(context.tr('{count} days', {'count': '$days'})),
                ),
              ],
            ),
            const SizedBox(height: 20),
            EmployeeTile(
              title: context.tr('Your reason'),
              subtitle: request.reason,
              icon: Icons.description_outlined,
            ),
            const SizedBox(height: 14),
            EmployeeTile(
              title: context.tr(
                request.status == LeaveRequestStatus.pending
                    ? 'Awaiting manager review'
                    : request.status == LeaveRequestStatus.approved
                    ? 'Approved'
                    : request.status == LeaveRequestStatus.rejected
                    ? 'Manager feedback'
                    : 'Cancelled',
              ),
              subtitle:
                  request.rejectionReason ??
                  context.tr('Submitted {time}', {
                    'time': date(request.createdAt),
                  }),
              icon: Icons.schedule_outlined,
            ),
            if (request.reviewedAt != null) ...[
              const SizedBox(height: 14),
              EmployeeTile(
                title: context.tr('Reviewed'),
                subtitle: date(request.reviewedAt!),
                icon: Icons.fact_check_outlined,
              ),
            ],
            if (request.canCancel) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  context.tr('You can cancel while this request is pending.'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
            if (state.failure != null) ...[
              const SizedBox(height: 16),
              Text(
                state.failure!.message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      );
    },
  );
}
