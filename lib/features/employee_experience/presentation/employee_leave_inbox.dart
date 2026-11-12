import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/utils/leave_request_display_formatters.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_form_dialog.dart';

import 'employee_leave_details_screen.dart';
import 'employee_tile.dart';

class EmployeeLeaveInbox extends StatelessWidget {
  const EmployeeLeaveInbox({required this.timezone, super.key});
  final String timezone;
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<EmployeeLeaveRequestsCubit, EmployeeLeaveRequestsState>(
    builder: (context, state) {
      final cubit = context.read<EmployeeLeaveRequestsCubit>();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(context.tr('All requests')),
                ),
                ButtonSegment(value: true, label: Text(context.tr('Pending'))),
              ],
              selected: {state.query.status == LeaveRequestStatus.pending},
              onSelectionChanged: state.refreshing
                  ? null
                  : (selection) => cubit.load(
                      query: LeaveRequestQuery(
                        status: selection.first
                            ? LeaveRequestStatus.pending
                            : null,
                      ),
                    ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => cubit.load(refresh: true),
              child: ListView(
                key: const Key('employee-leave-request-list'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  if (state.initialLoading) const AppContentLoading(),
                  if (state.failure != null) ...[
                    Text(
                      state.failure!.message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    TextButton(
                      onPressed: () => cubit.load(refresh: true),
                      child: Text(context.tr('Retry')),
                    ),
                  ],
                  if (!state.initialLoading && state.requests.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(context.tr('No leave requests')),
                    ),
                  for (final request in state.requests) ...[
                    EmployeeTile(
                      key: Key('employee-request-${request.id}'),
                      icon: Icons.description_outlined,
                      title:
                          '${context.tr(leaveTypeLabel(request.type))} · ${WorkspaceTime.dateKey(request.startsAt, timezone)}',
                      subtitle:
                          '${context.tr(switch (request.status) {
                            LeaveRequestStatus.pending => 'Pending',
                            LeaveRequestStatus.approved => 'Approved',
                            LeaveRequestStatus.rejected => 'Declined',
                            LeaveRequestStatus.cancelled => 'Cancelled',
                            _ => 'Unavailable',
                          })} · ${WorkspaceTime.dateKey(request.endsAt, timezone)}',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => EmployeeLeaveDetailsScreen(
                            request: request,
                            timezone: timezone,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (state.hasMore)
                    TextButton(
                      onPressed: state.loadingMore ? null : cubit.loadMore,
                      child: Text(
                        context.tr(
                          state.loadingMore ? 'Loading content' : 'Load more',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: FilledButton(
                key: const Key('request-leave'),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: LeaveRequestFormDialog(timezone: timezone),
                  ),
                ),
                child: Text(context.tr('Request leave')),
              ),
            ),
          ),
        ],
      );
    },
  );
}
