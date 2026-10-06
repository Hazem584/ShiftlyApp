import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_display.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_details_dialog.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_form_dialog.dart';

part 'parts/employee_leave_requests_panel/private_employee_leave_card.dart';

class EmployeeLeaveRequestsPanel extends StatelessWidget {
  const EmployeeLeaveRequestsPanel({required this.timezone, super.key});
  final String timezone;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<EmployeeLeaveRequestsCubit, EmployeeLeaveRequestsState>(
    builder: (context, state) {
      if (state.initialLoading) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(),
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: () =>
            context.read<EmployeeLeaveRequestsCubit>().load(refresh: true),
        child: ListView(
          key: const Key('employee-leave-request-list'),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'My leave requests',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton.icon(
                  key: const Key('request-leave'),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => BlocProvider.value(
                      value: context.read<EmployeeLeaveRequestsCubit>(),
                      child: LeaveRequestFormDialog(timezone: timezone),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Request leave'),
                ),
              ],
            ),
            if (state.failure != null) ...[
              const SizedBox(height: AppSpacing.s),
              Text(
                state.failure!.message,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            const SizedBox(height: AppSpacing.m),
            if (state.requests.isEmpty)
              EmptyState(
                icon: state.failure == null
                    ? Icons.event_note_outlined
                    : Icons.cloud_off_outlined,
                title: state.failure == null
                    ? 'No leave requests'
                    : 'Could not load requests',
                message:
                    state.failure?.message ??
                    'Requests you submit for this workspace will appear here.',
                action: state.failure == null
                    ? null
                    : FilledButton(
                        onPressed: context
                            .read<EmployeeLeaveRequestsCubit>()
                            .load,
                        child: const Text('Retry'),
                      ),
              )
            else
              for (final request in state.requests) ...[
                _EmployeeLeaveCard(
                  request: request,
                  timezone: timezone,
                  cancelling: state.cancellingIds.contains(request.id),
                ),
                const SizedBox(height: 10),
              ],
            if (state.hasMore)
              OutlinedButton(
                onPressed: state.loadingMore
                    ? null
                    : context.read<EmployeeLeaveRequestsCubit>().loadMore,
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
