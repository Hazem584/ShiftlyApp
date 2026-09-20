import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/models/attendance_record.dart';
import 'package:shiftly/core/routing/app_routes.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/surface_card.dart';

class DashboardActivitySection extends StatelessWidget {
  const DashboardActivitySection({required this.records, super.key});
  final List<AttendanceRecord> records;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Recent attendance', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.s),
      SurfaceCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var index = 0; index < records.length; index++) ...[
              _ActivityTile(record: records[index]),
              if (index < records.length - 1)
                const Divider(height: 1, indent: 64, endIndent: 14),
            ],
          ],
        ),
      ),
    ],
  );
}

class DashboardApprovalsCard extends StatelessWidget {
  const DashboardApprovalsCard({required this.pendingRequests, super.key});
  final int pendingRequests;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Pending approvals', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.s),
      SurfaceCard(
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.pending_actions_outlined,
                color: AppColors.warning,
                size: 22,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$pendingRequests requests waiting',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Text(
                    'Review attendance and leave requests',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => context.go(AppRoutes.attendanceLeaveRequests),
              tooltip: 'Review requests',
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.record});
  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    leading: CircleAvatar(
      backgroundColor: AppColors.field,
      foregroundColor: AppColors.ink,
      child: Text(
        record.employeeName.substring(0, 1),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    title: Text(
      record.employeeName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    ),
    subtitle: Text(record.isLate ? 'Checked in late' : 'Checked in for work'),
    trailing: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _time(record.occurredAt),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
        Text(
          record.isLate ? 'Late' : 'Present',
          style: TextStyle(
            color: record.isLate ? AppColors.warning : AppColors.success,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

String _time(DateTime value) =>
    '${value.hour % 12 == 0 ? 12 : value.hour % 12}:${value.minute.toString().padLeft(2, '0')} ${value.hour >= 12 ? 'PM' : 'AM'}';
