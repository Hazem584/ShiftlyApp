import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/core/widgets/screen_header.dart';
import 'package:shiftly/features/shifts/data/shift_repository.dart';
import 'package:shiftly/features/shifts/presentation/cubit/employee_shifts_cubit.dart';
import 'package:shiftly/features/shifts/presentation/widgets/shift_card.dart';

class EmployeeShiftsScreen extends StatelessWidget {
  const EmployeeShiftsScreen({super.key});

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
    return BlocConsumer<EmployeeShiftsCubit, EmployeeShiftsState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure && current.failure != null,
      listener: (context, state) =>
          ToastService.error(context, message: state.failure!.message),
      builder: (context, state) {
        if (state.initialLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.records.isEmpty) {
          return RefreshIndicator(
            onRefresh: () =>
                context.read<EmployeeShiftsCubit>().load(refresh: true),
            child: ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 14, 18, 0),
                  child: ScreenHeader(
                    title: 'Legacy shifts',
                    subtitle: 'Historical assigned schedules',
                  ),
                ),
                SizedBox(
                  height: 420,
                  child: EmptyState(
                    icon: state.failure == null
                        ? Icons.event_available_outlined
                        : Icons.cloud_off_outlined,
                    title: state.failure == null
                        ? 'No legacy shift history'
                        : 'Could not load shifts',
                    message: state.failure?.message ?? 'Use Fixed shifts for available templates and attendance.',
                  ),
                ),
              ],
            ),
          );
        }
        final now = DateTime.now().toUtc();
        final upcoming = state.records
            .where(
              (item) =>
                  item.status == ShiftStatus.scheduled &&
                  item.endsAt.isAfter(now),
            )
            .toList(growable: false);
        final history = state.records
            .where((item) => !upcoming.contains(item))
            .toList(growable: false);
        return RefreshIndicator(
          onRefresh: () =>
              context.read<EmployeeShiftsCubit>().load(refresh: true),
          child: ListView(
            key: const Key('employee-shifts-list'),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            children: [
              const ScreenHeader(
                title: 'Legacy shifts',
                subtitle: 'Historical assigned schedules and active clock-out',
              ),
              if (state.failure != null) ...[
                const SizedBox(height: AppSpacing.s),
                Text(
                  state.failure!.message,
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
              if (upcoming.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.l),
                Text(
                  'Legacy schedules',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.s),
                for (final shift in upcoming) ...[
                  ShiftCard(
                    key: Key('employee-shift-${shift.id}'),
                    shift: shift,
                    timezone: timezone,
                    onTap: () => _openDetails(context, shift.id, timezone),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
              if (history.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.l),
                Text('History', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.s),
                for (final shift in history) ...[
                  ShiftCard(
                    key: Key('employee-shift-${shift.id}'),
                    shift: shift,
                    timezone: timezone,
                    onTap: () => _openDetails(context, shift.id, timezone),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
              if (state.hasMore)
                OutlinedButton(
                  onPressed: state.loadingMore
                      ? null
                      : context.read<EmployeeShiftsCubit>().loadMore,
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

  Future<void> _openDetails(
    BuildContext context,
    String shiftId,
    String timezone,
  ) async {
    final record = await context.read<EmployeeShiftsCubit>().loadDetails(
      shiftId,
    );
    if (record == null || !context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Shift details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.s),
              ShiftStatusBadge(status: record.status),
              const SizedBox(height: AppSpacing.m),
              Text(
                'Starts: ${WorkspaceTime.dateTime(record.startsAt, timezone)}',
              ),
              Text('Ends: ${WorkspaceTime.dateTime(record.endsAt, timezone)}'),
              Text('Break: ${record.breakMinutes} minutes'),
              if (record.notes != null) ...[
                const SizedBox(height: AppSpacing.s),
                Text(record.notes!),
              ],
              if (record.attendance case final attendance?) ...[
                const SizedBox(height: AppSpacing.m),
                Text(
                  'Clock-in: ${WorkspaceTime.time(attendance.clockInAt, timezone)}',
                ),
                Text(
                  'Clock-out: ${WorkspaceTime.time(attendance.clockOutAt, timezone)}',
                ),
                Text(attendanceReviewLabel(attendance.reviewStatus)),
              ],
              if (record.canClockOut) ...[
                const SizedBox(height: AppSpacing.l),
                BlocBuilder<EmployeeShiftsCubit, EmployeeShiftsState>(
                  builder: (context, state) {
                    final clockingOut = state.clockingOutIds.contains(
                      record.id,
                    );
                    return FilledButton.icon(
                      key: Key('clock-out-${record.id}'),
                      onPressed: clockingOut
                          ? null
                          : () async {
                              final result = await context
                                  .read<EmployeeShiftsCubit>()
                                  .clockOut(record.id);
                              if (!context.mounted) return;
                              if (result == ClockMutationResult.success) {
                                Navigator.pop(sheetContext);
                                ToastService.success(
                                  context,
                                  message: 'Clock-out recorded.',
                                );
                              }
                            },
                      icon: clockingOut
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.fingerprint_rounded),
                      label: const Text('Clock out'),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
