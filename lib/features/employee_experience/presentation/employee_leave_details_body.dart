import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/utils/leave_request_display_formatters.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_display.dart';

import 'employee_tile.dart';

class EmployeeLeaveDetailsBody extends StatelessWidget {
  const EmployeeLeaveDetailsBody({
    required this.request,
    required this.state,
    required this.timezone,
    super.key,
  });

  final LeaveRequestRecord request;
  final EmployeeLeaveRequestsState state;
  final String timezone;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    String date(DateTime d) =>
        WorkspaceTime.dateTime(d, timezone, locale: locale);
    final from = WorkspaceTime.inWorkspace(request.startsAt, timezone);
    final to = WorkspaceTime.inWorkspace(request.endsAt, timezone);
    final days =
        DateTime.utc(
          to.year,
          to.month,
          to.day,
        ).difference(DateTime.utc(from.year, from.month, from.day)).inDays +
        1;
    final statusTitle = switch (request.status) {
      LeaveRequestStatus.pending => 'Awaiting manager review',
      LeaveRequestStatus.approved => 'Approved',
      LeaveRequestStatus.rejected => 'Manager feedback',
      _ => 'Cancelled',
    };
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '${context.tr(leaveTypeLabel(request.type))} · ${date(request.startsAt)} → ${date(request.endsAt)}',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            LeaveStatusBadge(status: request.status),
            Chip(label: Text(context.tr('{count} days', {'count': '$days'}))),
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
          title: context.tr(statusTitle),
          subtitle:
              request.rejectionReason ??
              context.tr('Submitted {time}', {'time': date(request.createdAt)}),
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
    );
  }
}
