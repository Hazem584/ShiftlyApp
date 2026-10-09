import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/points/domain/entities/points_models.dart';
import 'package:shiftly/features/points/presentation/cubit/points_cubit.dart';
import 'package:shiftly/features/points/presentation/widgets/points_empty.dart';
import 'package:shiftly/features/points/presentation/widgets/points_formatters.dart';

class PointsCalendar extends StatelessWidget {
  const PointsCalendar({required this.state, super.key});
  final PointsState state;

  @override
  Widget build(BuildContext context) {
    final month = state.visibleMonth ?? DateTime.now();
    final first = DateTime(month.year, month.month);
    final count = DateTime(month.year, month.month + 1, 0).day;
    final offset = first.weekday - 1;
    final byDate = {
      for (final day in state.visibleCalendar) day.date.value: day,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                monthLabel(month),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: 'Previous month',
              onPressed: () => context.read<PointsCubit>().changeMonth(
                DateTime(month.year, month.month - 1),
              ),
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed: () => context.read<PointsCubit>().changeMonth(
                DateTime(month.year, month.month + 1),
              ),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _legend(context),
        const SizedBox(height: 10),
        if (state.loadingCalendar) const LinearProgressIndicator(),
        if (state.calendarFailure != null && !state.calendarMatchesVisibleMonth)
          const PointsEmpty(
            icon: Icons.event_busy_outlined,
            text: 'This month could not be loaded. Pull to refresh or retry.',
          )
        else
          GridView.builder(
            key: const Key('performance-calendar'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: offset + count,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
            ),
            itemBuilder: (context, index) {
              if (index < offset) return const SizedBox.shrink();
              final number = index - offset + 1;
              final key =
                  '${month.year}-${month.month.toString().padLeft(2, '0')}-${number.toString().padLeft(2, '0')}';
              return _calendarCell(
                context,
                number,
                byDate[key],
                key ==
                    WorkspaceTime.dateKey(
                      DateTime.now(),
                      state.wallet!.timezone,
                    ),
              );
            },
          ),
      ],
    );
  }
}

Widget _legend(BuildContext context) => Semantics(
  label: 'Calendar status legend',
  child: Wrap(
    key: const Key('calendar-legend'),
    spacing: 10,
    runSpacing: 8,
    children: PerformanceStatus.values
        .where((status) => status != PerformanceStatus.unknown)
        .map(
          (status) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                statusIcon(status),
                size: 14,
                color: statusColor(context, status),
              ),
              const SizedBox(width: 3),
              Text(
                statusLabel(status),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        )
        .toList(),
  ),
);

Widget _calendarCell(
  BuildContext context,
  int number,
  PerformanceDay? day,
  bool isToday,
) {
  final status = day?.status;
  final color = statusColor(context, status);
  return Semantics(
    label:
        'Day $number, ${statusLabel(status)}${day?.extraEffort == true ? ', extra effort' : ''}${isToday ? ', today' : ''}',
    button: day != null,
    child: InkWell(
      onTap: day == null
          ? null
          : () => _showDay(
              context,
              day,
              context.read<PointsCubit>().state.wallet!.timezone,
            ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday
                ? Theme.of(context).colorScheme.primary
                : color.withValues(alpha: .35),
            width: isToday ? 2 : 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text('$number'),
            if (status != null)
              Positioned(
                bottom: 4,
                child: Icon(statusIcon(status), size: 11, color: color),
              ),
            if (day?.extraEffort == true)
              const Positioned(
                top: 2,
                right: 2,
                child: Icon(Icons.star_rounded, size: 12, color: Colors.amber),
              ),
          ],
        ),
      ),
    ),
  );
}

void _showDay(
  BuildContext context,
  PerformanceDay day,
  String timezone,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(day.date.value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              statusIcon(day.status),
              color: statusColor(context, day.status),
            ),
            title: Text(statusLabel(day.status)),
            subtitle: day.status == PerformanceStatus.pending
                ? const Text(
                    'This day is unresolved. It is not recorded as an absence.',
                  )
                : null,
          ),
          if (day.templateName != null) detailRow('Shift', day.templateName!),
          detailRow(
            'Clock in',
            WorkspaceTime.time(
              day.clockInAt,
              timezone,
              locale: Localizations.localeOf(context).toString(),
            ),
          ),
          detailRow(
            'Clock out',
            WorkspaceTime.time(
              day.clockOutAt,
              timezone,
              locale: Localizations.localeOf(context).toString(),
            ),
          ),
          if (day.workDurationMinutes != null)
            detailRow('Worked', '${day.workDurationMinutes} minutes'),
          if (day.lateMinutes != null)
            detailRow('Late', '${day.lateMinutes} minutes'),
          if (day.extraEffort) detailRow('Extra effort', 'Recognized'),
          if (day.pointChanges.isNotEmpty) ...[
            const Divider(),
            Text(
              'Point changes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ...day.pointChanges.map(
              (change) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(pointIcon(change.type)),
                title: Text(pointLabel(change.type)),
                trailing: Text(
                  '${change.amount > 0 ? '+' : ''}${change.amount}',
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  ),
);
