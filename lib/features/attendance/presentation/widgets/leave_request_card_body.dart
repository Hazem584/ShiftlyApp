import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/utils/leave_request_card_formatters.dart';
import 'package:shiftly/features/attendance/presentation/utils/leave_request_display_formatters.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_detail_row.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_display.dart';

List<Widget> buildLeaveRequestCardBody(
  BuildContext context,
  LeaveRequestRecord request,
  String timezone,
) {
  final locale = Localizations.localeOf(context).toString();
  return [
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
          locale: locale,
        )).toString(),
        'value2': (WorkspaceTime.dateTime(
          request.endsAt,
          timezone,
          locale: locale,
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
          locale: locale,
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
  ];
}
