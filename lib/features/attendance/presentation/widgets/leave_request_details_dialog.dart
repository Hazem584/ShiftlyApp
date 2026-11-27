import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/utils/leave_request_display_formatters.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_detail_row.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_display.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_dialog.dart';

class LeaveRequestDetailsDialog extends StatelessWidget {
  const LeaveRequestDetailsDialog({
    required this.request,
    required this.timezone,
    super.key,
  });
  final LeaveRequestRecord request;
  final String timezone;

  String _formatDate(BuildContext context, DateTime value) =>
      WorkspaceTime.dateTime(
        value,
        timezone,
        locale: Localizations.localeOf(context).toString(),
      );

  @override
  Widget build(BuildContext context) => ManagerDialog(
    title: Row(
      children: [
        Expanded(child: Text(context.tr(leaveTypeLabel(request.type)))),
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
            text: context.tr('Starts: {value1}', {
              'value1': _formatDate(context, request.startsAt),
            }),
          ),
          const SizedBox(height: 8),
          LeaveDetailRow(
            icon: Icons.event_available_outlined,
            text: context.tr('Ends: {value1}', {
              'value1': _formatDate(context, request.endsAt),
            }),
          ),
          const SizedBox(height: 8),
          LeaveDetailRow(icon: Icons.notes_rounded, text: request.reason),
          const SizedBox(height: 8),
          LeaveDetailRow(
            icon: Icons.schedule_rounded,
            text: context.tr('Submitted: {value1}', {
              'value1': _formatDate(context, request.createdAt),
            }),
          ),
          if (request.reviewedAt != null) ...[
            const SizedBox(height: 8),
            LeaveDetailRow(
              icon: Icons.fact_check_outlined,
              text: context.tr('Reviewed: {value1}', {
                'value1': _formatDate(context, request.reviewedAt!),
              }),
            ),
          ],
          if (request.rejectionReason?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            LeaveDetailRow(
              icon: Icons.info_outline,
              text: context.tr('Rejection reason: {value1}', {
                'value1': (request.rejectionReason).toString(),
              }),
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.tr('Close')),
      ),
    ],
  );
}
