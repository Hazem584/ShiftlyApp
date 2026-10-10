import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_metric.dart';

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
                Icon(
                  Icons.approval_outlined,
                  color: AppPalette.of(context).orange,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr('Manager review queue'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppPalette.of(context).warningSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Text(
                      context.tr('{value1} pending', {
                        'value1': (pending).toString(),
                      }),
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
      BlocBuilder<ManagerAttendanceCubit, ManagerAttendanceState>(
        builder: (context, state) => LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 640
                ? 3
                : MediaQuery.textScalerOf(context).scale(14) > 21
                ? 1
                : 2;
            final width = (constraints.maxWidth - 10 * (columns - 1)) / columns;
            final unavailable =
                state.initialLoading ||
                (state.failure != null && state.records.isEmpty);
            final metrics = [
              (
                'Attendance records',
                state.records.length,
                Icons.fact_check_outlined,
                AppPalette.of(context).ink,
              ),
              (
                'Open attendance',
                state.records.where((record) => record.isOpen).length,
                Icons.login_rounded,
                AppPalette.of(context).teal,
              ),
              (
                'Needs review',
                state.records.where((record) => record.canReview).length,
                Icons.approval_outlined,
                AppPalette.of(context).orange,
              ),
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final metric in metrics)
                      SizedBox(
                        width: width,
                        child: AttendanceMetric(
                          label: metric.$1,
                          value: unavailable ? '—' : '${metric.$2}',
                          icon: metric.$3,
                          color: metric.$4,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('Based on the attendance records shown below.'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          },
        ),
      ),
    ],
  );
}
