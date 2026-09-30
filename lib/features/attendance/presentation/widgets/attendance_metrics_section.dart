import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';

class AttendanceMetricsSection extends StatelessWidget {
  const AttendanceMetricsSection({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      BlocBuilder<LeaveRequestsCubit, LeaveRequestsState>(
        builder: (context, state) {
          final pending = state.pendingCount;
          return SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.approval_outlined, color: AppColors.orange),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Manager review queue',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.warningSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Text(
                      '$pending pending',
                      key: const Key('pending-request-count'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      const SizedBox(height: AppSpacing.m),
      const SizedBox(
        height: 104,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _AttendanceMetric(
                label: 'Attendance Rate',
                value: '94.2%',
                icon: Icons.trending_up_rounded,
                color: AppColors.success,
              ),
              SizedBox(width: 10),
              _AttendanceMetric(
                label: 'Hours Worked',
                value: '168h',
                icon: Icons.schedule_rounded,
                color: AppColors.ink,
              ),
              SizedBox(width: 10),
              _AttendanceMetric(
                label: 'Avg Hours/Day',
                value: '8.4h',
                icon: Icons.calendar_month_outlined,
                color: AppColors.orange,
              ),
              SizedBox(width: 10),
              _AttendanceMetric(
                label: 'Leave Requests',
                value: '1',
                icon: Icons.error_outline_rounded,
                color: AppColors.warning,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _AttendanceMetric extends StatelessWidget {
  const _AttendanceMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 172,
    child: SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Flexible(
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: color, size: 27),
        ],
      ),
    ),
  );
}
