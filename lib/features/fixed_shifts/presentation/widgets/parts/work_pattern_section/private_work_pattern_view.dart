part of '../../work_pattern_section.dart';

class _WorkPatternView extends StatelessWidget {
  const _WorkPatternView({required this.timezone, required this.canEdit});
  final String timezone;
  final bool canEdit;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<WorkPatternCubit, WorkPatternState>(
    builder: (context, state) {
      if (state.loading) {
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
              _WeekdayRow(days: current.expectedWeekdays),
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
                      title: _WeekdayRow(days: pattern.expectedWeekdays),
                      subtitle: Text(
                        '${pattern.effectiveFrom} → ${pattern.effectiveTo ?? 'ongoing'}',
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                key: const Key('replace-work-pattern'),
                onPressed:
                    !canEdit || state.saving || !WorkspaceTime.isValid(timezone)
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

  Future<void> _replace(BuildContext context) async {
    final zoneNow = WorkspaceTime.inWorkspace(DateTime.now().toUtc(), timezone);
    final result = await showDialog<({Set<int> days, DateTime date})>(
      context: context,
      builder: (_) => _PatternDialog(
        today: DateTime(zoneNow.year, zoneNow.month, zoneNow.day),
      ),
    );
    if (result == null || !context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create a new pattern version?'),
        content: Text(
          'Effective ${_dateKey(result.date)}. The previous version will end the day before; historical records remain unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-work-pattern'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Create version'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<WorkPatternCubit>().replace(
      weekdays: result.days,
      effectiveFrom: _dateKey(result.date),
    );
  }
}
