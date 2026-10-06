import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/fixed_shifts/data/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';

class WorkPatternSection extends StatelessWidget {
  const WorkPatternSection({
    required this.workspaceId,
    required this.membershipId,
    required this.timezone,
    required this.canEdit,
    super.key,
  });
  final String workspaceId;
  final String membershipId;
  final String timezone;
  final bool canEdit;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        WorkPatternCubit(context.read<FixedShiftRepository>())
          ..bind(workspaceId: workspaceId, membershipId: membershipId),
    child: _WorkPatternView(timezone: timezone, canEdit: canEdit),
  );
}

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

class _PatternDialog extends StatefulWidget {
  const _PatternDialog({required this.today});
  final DateTime today;
  @override
  State<_PatternDialog> createState() => _PatternDialogState();
}

class _PatternDialogState extends State<_PatternDialog> {
  final _days = <int>{};
  late DateTime _date;
  static const _labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    _date = widget.today;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('New work pattern'),
    content: SizedBox(
      width: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Working weekdays',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (var day = 0; day < 7; day++)
                FilterChip(
                  key: Key('weekday-$day'),
                  label: Text(_labels[day]),
                  selected: _days.contains(day),
                  onSelected: (selected) => setState(
                    () => selected ? _days.add(day) : _days.remove(day),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event_outlined),
            label: Text('Effective ${_dateKey(_date)}'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Today or a future workspace-local date. This creates a new version.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _days.isEmpty
            ? null
            : () => Navigator.pop(context, (
                days: Set<int>.from(_days),
                date: _date,
              )),
        child: const Text('Continue'),
      ),
    ],
  );

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      firstDate: widget.today,
      lastDate: DateTime(widget.today.year + 5, 12, 31),
      initialDate: _date,
    );
    if (value != null && !value.isBefore(widget.today)) {
      setState(() => _date = value);
    }
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow({required this.days});
  final List<int> days;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 5,
    runSpacing: 5,
    children: [
      for (final day in days)
        Chip(
          label: Text(
            const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][day],
          ),
          visualDensity: VisualDensity.compact,
        ),
    ],
  );
}

String _dateKey(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
