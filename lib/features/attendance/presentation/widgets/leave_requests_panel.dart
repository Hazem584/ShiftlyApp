import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_card.dart';

class LeaveRequestsPanel extends StatelessWidget {
  const LeaveRequestsPanel({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LeaveRequestsCubit, LeaveRequestsState>(
        builder: (context, state) => switch (state) {
          LeaveRequestsLoading() => const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
          LeaveRequestsError(:final message) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load requests',
            message: message,
            action: FilledButton(
              onPressed: context.read<LeaveRequestsCubit>().load,
              child: const Text('Retry'),
            ),
          ),
          LeaveRequestsLoaded(:final requests, :final updatingId) =>
            requests.isEmpty
                ? const EmptyState(
                    icon: Icons.event_available_outlined,
                    title: 'All caught up',
                    message:
                        'New employee requests will appear here for review.',
                  )
                : Column(
                    key: const Key('leave-request-list'),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Employee requests',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Text(
                            '${requests.length} total',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s),
                      for (final request in requests) ...[
                        LeaveRequestCard(
                          request: request,
                          updating: updatingId == request.id,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
        },
      );
}
