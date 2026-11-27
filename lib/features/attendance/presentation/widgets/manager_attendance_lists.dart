import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_records_list.dart';
import 'package:shiftly/features/attendance/presentation/widgets/manager_attendance_details_sheet.dart';

Widget buildManagerAttendanceEmptyView(
  BuildContext context,
  ManagerAttendanceState state,
) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      context.tr('Recent Attendance'),
      style: Theme.of(context).textTheme.titleLarge,
    ),
    EmptyState(
      icon: state.failure == null
          ? Icons.fact_check_outlined
          : Icons.cloud_off_outlined,
      title: state.failure == null
          ? 'No attendance yet'
          : 'Could not load attendance',
      message:
          state.failure?.message ??
          'Employee clock-in records will appear here.',
      action: state.failure == null
          ? null
          : FilledButton(
              onPressed: context.read<ManagerAttendanceCubit>().load,
              child: Text(context.tr('Retry')),
            ),
    ),
  ],
);

List<Widget> buildManagerAttendanceListSections(
  BuildContext context,
  ManagerAttendanceState state,
  String timezone,
) => [
  if (state.pending.isNotEmpty) ...[
    const SizedBox(height: AppSpacing.l),
    AttendanceRecordsList(
      records: state.pending,
      timezone: timezone,
      title: context.tr('Pending attendance requests'),
      onTap: (r) => showManagerAttendanceDetails(context, r.id, timezone),
      trailing: (record) => state.reviewingIds.contains(record.id)
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right_rounded),
    ),
    if (state.hasMorePending)
      OutlinedButton(
        onPressed: state.loadingMorePending
            ? null
            : context.read<ManagerAttendanceCubit>().loadMorePending,
        child: Text(context.tr('Load more requests')),
      ),
  ],
  if (state.records.isNotEmpty) ...[
    const SizedBox(height: AppSpacing.l),
    AttendanceRecordsList(
      records: state.records,
      timezone: timezone,
      onTap: (r) => showManagerAttendanceDetails(context, r.id, timezone),
    ),
    if (state.hasMore)
      OutlinedButton(
        onPressed: state.loadingMore
            ? null
            : context.read<ManagerAttendanceCubit>().loadMore,
        child: Text(context.tr('Load more attendance')),
      ),
  ],
];
