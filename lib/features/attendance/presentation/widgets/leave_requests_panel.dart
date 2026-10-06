import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_card.dart';

part 'parts/leave_requests_panel/private_filters.dart';

class LeaveRequestsPanel extends StatelessWidget {
  const LeaveRequestsPanel({required this.timezone, super.key});
  final String timezone;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LeaveRequestsCubit, LeaveRequestsState>(
        builder: (context, state) {
          if (state.initialLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (state.requests.isEmpty && state.failure != null) {
            return EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load requests',
              message: state.failure!.message,
              action: FilledButton(
                onPressed: context.read<LeaveRequestsCubit>().load,
                child: const Text('Retry'),
              ),
            );
          }
          return Column(
            key: const Key('leave-request-list'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Filters(state: state),
              const SizedBox(height: AppSpacing.m),
              if (state.failure != null) ...[
                Text(
                  state.failure!.message,
                  style: const TextStyle(color: AppColors.error),
                ),
                const SizedBox(height: AppSpacing.s),
              ],
              if (state.requests.isEmpty)
                const EmptyState(
                  icon: Icons.event_available_outlined,
                  title: 'All caught up',
                  message: 'New employee requests will appear here for review.',
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Employee requests',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      '${state.requests.length} loaded',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s),
                for (final request in state.requests) ...[
                  LeaveRequestCard(
                    request: request,
                    updating: state.reviewingIds.contains(request.id),
                    timezone: timezone,
                  ),
                  const SizedBox(height: 10),
                ],
                if (state.hasMore)
                  OutlinedButton(
                    onPressed: state.loadingMore
                        ? null
                        : context.read<LeaveRequestsCubit>().loadMore,
                    child: state.loadingMore
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Load more'),
                  ),
              ],
            ],
          );
        },
      );
}

LeaveRequestQuery _query(
  LeaveRequestQuery current, {
  LeaveRequestStatus? status,
  LeaveRequestType? type,
  bool replaceStatus = false,
  bool replaceType = false,
}) => LeaveRequestQuery(
  limit: current.limit,
  from: current.from,
  to: current.to,
  status: replaceStatus ? status : current.status,
  type: replaceType ? type : current.type,
  employeeMembershipId: current.employeeMembershipId,
  search: current.search,
);
