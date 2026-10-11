import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/offline/read_sync_banner.dart';
import 'package:shiftly/core/offline/read_sync_state.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_attendance_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_records_list.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/flexible_attendance_panel.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/correction_request_dialog.dart';

class EmployeeAttendanceHistory extends StatelessWidget {
  const EmployeeAttendanceHistory({super.key, required this.timezone});
  final String timezone;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<EmployeeAttendanceCubit, EmployeeAttendanceState>(
    builder: (context, state) {
      if (state.initialLoading) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          children: [
            ReadSyncBanner(
              category: ReadCategory.attendance,
              onRefresh: () =>
                  context.read<EmployeeAttendanceCubit>().load(refresh: true),
            ),
            FlexibleAttendancePanel(timezone: timezone),
            const SizedBox(height: AppSpacing.l),
            const Center(child: CircularProgressIndicator()),
          ],
        );
      }
      if (state.records.isEmpty) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          children: [
            ReadSyncBanner(
              category: ReadCategory.attendance,
              onRefresh: () =>
                  context.read<EmployeeAttendanceCubit>().load(refresh: true),
            ),
            FlexibleAttendancePanel(timezone: timezone),
            const SizedBox(height: AppSpacing.l),
            EmptyState(
              icon: state.failure == null
                  ? Icons.history_toggle_off_rounded
                  : Icons.cloud_off_outlined,
              title: state.failure == null
                  ? 'No attendance history'
                  : 'Could not load attendance',
              message:
                  state.failure?.message ??
                  'Your clock-in and clock-out records will appear here.',
              action: state.failure == null
                  ? null
                  : FilledButton(
                      onPressed: context.read<EmployeeAttendanceCubit>().load,
                      child: Text(context.tr('Retry')),
                    ),
            ),
          ],
        );
      }
      return RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            context.read<EmployeeAttendanceCubit>().load(refresh: true),
            context.read<FlexibleAttendanceCubit>().load(refresh: true),
          ]);
        },
        child: ListView(
          key: const Key('employee-attendance-list'),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          children: [
            ReadSyncBanner(
              category: ReadCategory.attendance,
              onRefresh: () =>
                  context.read<EmployeeAttendanceCubit>().load(refresh: true),
            ),
            FlexibleAttendancePanel(timezone: timezone),
            const SizedBox(height: AppSpacing.l),
            if (state.failure != null) ...[
              Text(
                state.failure!.message,
                style: TextStyle(color: AppPalette.of(context).error),
              ),
              const SizedBox(height: AppSpacing.s),
            ],
            AttendanceRecordsList(
              records: state.records,
              timezone: timezone,
              title: context.tr('Attendance history'),
              trailing: (record) =>
                  record.clockOutAt != null &&
                      record.reviewStatus != AttendanceReviewStatus.rejected
                  ? IconButton(
                      tooltip: context.tr('Request attendance correction'),
                      icon: const Icon(Icons.edit_calendar_outlined),
                      onPressed: () async {
                        final sent = await showCorrectionRequest(
                          context,
                          record,
                          record.workspaceTimezone ?? timezone,
                        );
                        if (sent == true && context.mounted) {
                          context.push('/team-work?tab=corrections');
                        }
                      },
                    )
                  : const SizedBox.shrink(),
            ),
            if (state.hasMore)
              OutlinedButton(
                onPressed: state.loadingMore
                    ? null
                    : context.read<EmployeeAttendanceCubit>().loadMore,
                child: state.loadingMore
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.tr('Load more')),
              ),
          ],
        ),
      );
    },
  );
}
