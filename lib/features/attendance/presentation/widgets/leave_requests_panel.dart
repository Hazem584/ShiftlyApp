import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_card.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_filters.dart';

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
              title: context.tr('Could not load requests'),
              message: state.failure!.message,
              action: FilledButton(
                onPressed: context.read<LeaveRequestsCubit>().load,
                child: Text(context.tr('Retry')),
              ),
            );
          }
          return Column(
            key: const Key('leave-request-list'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LeaveRequestFilters(state: state),
              const SizedBox(height: AppSpacing.m),
              if (state.failure != null) ...[
                Text(
                  state.failure!.message,
                  style: TextStyle(color: AppPalette.of(context).error),
                ),
                const SizedBox(height: AppSpacing.s),
              ],
              if (state.requests.isEmpty)
                EmptyState(
                  icon: Icons.event_available_outlined,
                  title: context.tr('All caught up'),
                  message: 'New employee requests will appear here for review.',
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('Employee requests'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      context.tr('{value1} loaded', {
                        'value1': (state.requests.length).toString(),
                      }),
                      style: TextStyle(
                        color: AppPalette.of(context).textSecondary,
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
                        : Text(context.tr('Load more')),
                  ),
              ],
            ],
          );
        },
      );
}
