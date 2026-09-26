import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/core/widgets/screen_header.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_attendance_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_records_list.dart';

class EmployeeAttendanceScreen extends StatelessWidget {
  const EmployeeAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timezone =
        context
            .watch<SessionCoordinator>()
            .state
            .activeMembership
            ?.workspace
            .timezone ??
        'Etc/UTC';
    return BlocBuilder<EmployeeAttendanceCubit, EmployeeAttendanceState>(
      builder: (context, state) {
        if (state.initialLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.records.isEmpty) {
          return EmptyState(
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
                    child: const Text('Retry'),
                  ),
          );
        }
        return RefreshIndicator(
          onRefresh: () =>
              context.read<EmployeeAttendanceCubit>().load(refresh: true),
          child: ListView(
            key: const Key('employee-attendance-list'),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            children: [
              const ScreenHeader(
                title: 'My Attendance',
                subtitle: 'Your attendance history for this workspace',
              ),
              if (state.failure != null) ...[
                const SizedBox(height: AppSpacing.s),
                Text(
                  state.failure!.message,
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
              const SizedBox(height: AppSpacing.l),
              AttendanceRecordsList(
                records: state.records,
                timezone: timezone,
                title: 'Attendance history',
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
                      : const Text('Load more'),
                ),
            ],
          ),
        );
      },
    );
  }
}
