import 'package:flutter/material.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_display.dart';

class LeaveRequestDetailsDialog extends StatelessWidget {
  const LeaveRequestDetailsDialog({
    required this.request,
    required this.timezone,
    super.key,
  });
  final LeaveRequestRecord request;
  final String timezone;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Row(
      children: [
        Expanded(child: Text(leaveTypeLabel(request.type))),
        LeaveStatusBadge(status: request.status),
      ],
    ),
    content: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            request.employee.displayName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          LeaveDetailRow(
            icon: Icons.calendar_today_outlined,
            text:
                'Starts: ${WorkspaceTime.dateTime(request.startsAt, timezone, locale: Localizations.localeOf(context).toString())}',
          ),
          const SizedBox(height: 8),
          LeaveDetailRow(
            icon: Icons.event_available_outlined,
            text:
                'Ends: ${WorkspaceTime.dateTime(request.endsAt, timezone, locale: Localizations.localeOf(context).toString())}',
          ),
          const SizedBox(height: 8),
          LeaveDetailRow(icon: Icons.notes_rounded, text: request.reason),
          const SizedBox(height: 8),
          LeaveDetailRow(
            icon: Icons.schedule_rounded,
            text:
                'Submitted: ${WorkspaceTime.dateTime(request.createdAt, timezone, locale: Localizations.localeOf(context).toString())}',
          ),
          if (request.reviewedAt != null) ...[
            const SizedBox(height: 8),
            LeaveDetailRow(
              icon: Icons.fact_check_outlined,
              text:
                  'Reviewed: ${WorkspaceTime.dateTime(request.reviewedAt!, timezone, locale: Localizations.localeOf(context).toString())}',
            ),
          ],
          if (request.rejectionReason?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            LeaveDetailRow(
              icon: Icons.info_outline,
              text: 'Rejection reason: ${request.rejectionReason}',
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  );
}
