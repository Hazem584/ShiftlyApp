import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/surface_card.dart';

import '../../data/fixed_shift_repository.dart';
import '../cubit/fixed_shifts_cubit.dart';
import 'assignment_form.dart';
import 'weekday_row.dart';

class WorkPatternView extends StatelessWidget {
  const WorkPatternView({
    super.key,
    required this.workspaceId,
    required this.timezone,
    required this.canEdit,
  });
  final String workspaceId;
  final String timezone;
  final bool canEdit;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<WorkPatternCubit, WorkPatternState>(
    builder: (context, state) {
      if (state.loading && state.history == null) {
        return const SurfaceCard(
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_view_week_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Work pattern',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh work pattern',
                  onPressed: () =>
                      context.read<WorkPatternCubit>().load(retain: true),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            if (state.loading) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            if (state.failure != null) ...[
              Text(
                state.failure!.message,
                style: const TextStyle(color: AppColors.error),
              ),
              if (state.failure!.requestId != null)
                Text(
                  'Support reference: ${state.failure!.requestId}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 8),
            ],
            if (state.history?.current case final current?) ...[
              const Text(
                'Current schedule',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                current.assignmentSnapshot?.summary ??
                    'Historical assignment evidence is not recorded.',
              ),
              WeekdayRow(days: current.expectedWeekdays),
              const SizedBox(height: 5),
              Text(
                'Effective ${current.effectiveFrom}${current.effectiveTo == null ? '' : ' through ${current.effectiveTo}'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else
              const Text('No work pattern is currently effective.'),
            if ((state.history?.history.length ?? 0) > 0) ...[
              const Divider(height: 28),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Version history (${state.history!.history.length})',
                ),
                subtitle: const Text(
                  'New patterns create versions; history is never overwritten.',
                ),
                children: [
                  for (final pattern in state.history!.history)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        pattern.effectiveTo == null
                            ? Icons.event_available_outlined
                            : Icons.history_rounded,
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pattern.id == state.history?.current?.id
                                ? 'Current assignment'
                                : pattern.effectiveFrom.compareTo(
                                        WorkspaceTime.dateKey(
                                          DateTime.now().toUtc(),
                                          timezone,
                                        ),
                                      ) >
                                      0
                                ? 'Future assignment'
                                : 'Historical assignment',
                          ),
                          WeekdayRow(days: pattern.expectedWeekdays),
                        ],
                      ),
                      subtitle: Text(
                        '${pattern.assignmentSnapshot?.summary ?? 'Assignment evidence not recorded'}\n'
                        '${pattern.effectiveFrom} → ${pattern.effectiveTo ?? 'ongoing'}',
                      ),
                    ),
                ],
              ),
            ],
            if (state.history?.pagination case final pagination?)
              if (pagination.totalPages > 1)
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: state.loading
                          ? null
                          : pagination.page > 1
                          ? () => context.read<WorkPatternCubit>().load(
                              retain: true,
                              page: pagination.page - 1,
                            )
                          : null,
                      child: const Text('Previous'),
                    ),
                    Text(
                      'Page ${pagination.page} of ${pagination.totalPages}',
                    ),
                    TextButton(
                      onPressed: state.loading
                          ? null
                          : pagination.page < pagination.totalPages
                          ? () => context.read<WorkPatternCubit>().load(
                              retain: true,
                              page: pagination.page + 1,
                            )
                          : null,
                      child: const Text('Next'),
                    ),
                  ],
                ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                key: const Key('replace-work-pattern'),
                onPressed:
                    !canEdit ||
                        state.saving ||
                        state.loading ||
                        !WorkspaceTime.isValid(timezone)
                    ? null
                    : () => _replace(context),
                icon: state.saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.edit_calendar_outlined),
                label: Text(
                  canEdit ? 'Schedule a new version' : 'Employee is inactive',
                ),
              ),
            ),
            if (!WorkspaceTime.isValid(timezone))
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'The workspace timezone is invalid. Pattern changes are disabled.',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
          ],
        ),
      );
    },
  );

  Future<void> _replace(BuildContext context) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AssignmentForm(
      repository: getIt.isRegistered<FixedShiftRepository>()
          ? getIt<FixedShiftRepository>()
          : context.read<FixedShiftRepository>(),
      cubit: context.read<WorkPatternCubit>(),
      workspaceId: workspaceId,
      timezone: timezone,
    ),
  );
}
