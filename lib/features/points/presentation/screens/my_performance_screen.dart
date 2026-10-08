import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/points/data/points_models.dart';
import 'package:shiftly/features/points/presentation/cubit/points_cubit.dart';

class MyPerformanceScreen extends StatelessWidget {
  const MyPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocConsumer<PointsCubit, PointsState>(
    listenWhen: (before, after) =>
        !before.redemptionSucceeded && after.redemptionSucceeded,
    listener: (context, state) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('RED compensation completed.')),
      );
    },
    builder: (context, state) {
      if (state.initialLoading) return const _PerformanceSkeleton();
      if (state.wallet == null) {
        return _FailureView(
          message: state.failure?.message ?? 'Unable to load your performance.',
        );
      }
      return RefreshIndicator(
        onRefresh: () => context.read<PointsCubit>().load(refresh: true),
        child: CustomScrollView(
          key: const Key('my-performance-content'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList.list(
                children: [
                  _Hero(wallet: state.wallet!),
                  if (state.partialFailure != null) ...[
                    const SizedBox(height: 12),
                    _InlineFailure(state: state),
                  ],
                  const SizedBox(height: 20),
                  _Wallet(wallet: state.wallet!),
                  const SizedBox(height: 20),
                  _Redemption(wallet: state.wallet!, state: state),
                  const SizedBox(height: 24),
                  _Calendar(state: state),
                  const SizedBox(height: 24),
                  _History(state: state),
                  const SizedBox(height: 24),
                  _Achievements(items: state.achievements),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.wallet});
  final PointsWallet wallet;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.primaryContainer,
          Theme.of(context).colorScheme.surfaceContainerHigh,
        ],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Performance',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text('${wallet.workspaceName} · ${wallet.timezone}'),
        const SizedBox(height: 20),
        Wrap(
          spacing: 28,
          runSpacing: 14,
          children: [
            _HeroValue(
              value: '${wallet.green.available}',
              label: 'Available GREEN',
              icon: Icons.eco_rounded,
            ),
            _HeroValue(
              value: '${wallet.currentStreak}',
              label: 'Current streak',
              icon: Icons.local_fire_department_rounded,
            ),
          ],
        ),
      ],
    ),
  );
}

class _HeroValue extends StatelessWidget {
  const _HeroValue({
    required this.value,
    required this.label,
    required this.icon,
  });
  final String value;
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: $value',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label),
      ],
    ),
  );
}

class _Wallet extends StatelessWidget {
  const _Wallet({required this.wallet});
  final PointsWallet wallet;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Points wallet', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth >= 620
              ? (constraints.maxWidth - 24) / 3
              : (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _BalanceCard(
                'GREEN available',
                wallet.green.available,
                Icons.eco,
                Colors.green,
                width,
              ),
              _BalanceCard(
                'Active RED',
                wallet.red.active,
                Icons.error_outline,
                Colors.red,
                width,
              ),
              _BalanceCard(
                'BLACK this month',
                wallet.black.currentMonth,
                Icons.timelapse,
                Colors.blueGrey,
                width,
              ),
              _BalanceCard(
                'ORANGE',
                wallet.orange.total,
                Icons.pending_actions,
                Colors.orange,
                width,
              ),
              _BalanceCard(
                'BLUE',
                wallet.blue.total,
                Icons.volunteer_activism,
                Colors.blue,
                width,
              ),
            ],
          );
        },
      ),
    ],
  );
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard(this.label, this.value, this.icon, this.color, this.width);
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final double width;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label balance: $value',
    child: Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text('$value', style: Theme.of(context).textTheme.titleLarge),
          Text(label, maxLines: 2),
        ],
      ),
    ),
  );
}

class _Redemption extends StatelessWidget {
  const _Redemption({required this.wallet, required this.state});
  final PointsWallet wallet;
  final PointsState state;
  @override
  Widget build(BuildContext context) {
    final eligible = wallet.maxRedeemable > 0 && !state.redeeming;
    final progress = (wallet.green.available / wallet.greenCostPerRed).clamp(
      0.0,
      1.0,
    );
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compensate RED',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text('${wallet.greenCostPerRed} GREEN compensates 1 RED'),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text(
              wallet.greenNeededForOneRed == 0
                  ? 'You have enough GREEN for your next compensation.'
                  : '${wallet.greenNeededForOneRed} more GREEN needed.',
            ),
            if (state.domainCode != null) ...[
              const SizedBox(height: 8),
              Text(
                _domainMessage(state.domainCode!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (state.canRetryRedemption) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: state.redeeming
                    ? null
                    : () => context.read<PointsCubit>().redeem(1, retry: true),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry same redemption'),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('redeem-red-button'),
                onPressed: eligible
                    ? () => _confirmRedemption(context, wallet)
                    : null,
                icon: state.redeeming
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.redeem_rounded),
                label: const Text('Compensate 1 RED'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({required this.state});
  final PointsState state;
  @override
  Widget build(BuildContext context) {
    final month = state.visibleMonth ?? DateTime.now();
    final first = DateTime(month.year, month.month);
    final count = DateTime(month.year, month.month + 1, 0).day;
    final offset = first.weekday - 1;
    final byDate = {for (final day in state.calendar) day.date.value: day};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _monthLabel(month),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: 'Previous month',
              onPressed: state.loadingCalendar
                  ? null
                  : () => context.read<PointsCubit>().changeMonth(
                      DateTime(month.year, month.month - 1),
                    ),
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed: state.loadingCalendar
                  ? null
                  : () => context.read<PointsCubit>().changeMonth(
                      DateTime(month.year, month.month + 1),
                    ),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const _Legend(),
        const SizedBox(height: 10),
        if (state.loadingCalendar) const LinearProgressIndicator(),
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
            final day = byDate[key];
            return _CalendarCell(
              number: number,
              day: day,
              isToday:
                  key ==
                  WorkspaceTime.dateKey(DateTime.now(), state.wallet!.timezone),
            );
          },
        ),
      ],
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.number,
    required this.day,
    required this.isToday,
  });
  final int number;
  final PerformanceDay? day;
  final bool isToday;
  @override
  Widget build(BuildContext context) {
    final status = day?.status;
    final color = _statusColor(context, status);
    return Semantics(
      label:
          'Day $number, ${_statusLabel(status)}${day?.extraEffort == true ? ', extra effort' : ''}${isToday ? ', today' : ''}',
      button: day != null,
      child: InkWell(
        onTap: day == null
            ? null
            : () => _showDay(
                context,
                day!,
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
                  child: Icon(_statusIcon(status), size: 11, color: color),
                ),
              if (day?.extraEffort == true)
                const Positioned(
                  top: 2,
                  right: 2,
                  child: Icon(
                    Icons.star_rounded,
                    size: 12,
                    color: Colors.amber,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Calendar status legend',
    child: Wrap(
      key: const Key('calendar-legend'),
      spacing: 10,
      runSpacing: 8,
      children: PerformanceStatus.values
          .where((s) => s != PerformanceStatus.unknown)
          .map(
            (status) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _statusIcon(status),
                  size: 14,
                  color: _statusColor(context, status),
                ),
                const SizedBox(width: 3),
                Text(
                  _statusLabel(status),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          )
          .toList(),
    ),
  );
}

class _History extends StatelessWidget {
  const _History({required this.state});
  final PointsState state;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Recent activity', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      if (state.history.isEmpty)
        const _Empty(
          icon: Icons.receipt_long_outlined,
          text: 'No points activity yet.',
        )
      else
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: state.history
                .map(
                  (entry) => ListTile(
                    leading: CircleAvatar(child: Icon(_pointIcon(entry.type))),
                    title: Text(_reason(entry.reason)),
                    subtitle: Text(
                      entry.operationalDate?.value ??
                          WorkspaceTime.dateTime(
                            entry.createdAt,
                            state.wallet!.timezone,
                          ),
                    ),
                    trailing: Text(
                      '${entry.amount > 0 ? '+' : ''}${entry.amount} ${_pointLabel(entry.type)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      if (state.hasMoreHistory)
        Center(
          child: TextButton(
            onPressed: state.loadingMoreHistory
                ? null
                : context.read<PointsCubit>().loadMoreHistory,
            child: Text(state.loadingMoreHistory ? 'Loading…' : 'Load more'),
          ),
        ),
    ],
  );
}

class _Achievements extends StatelessWidget {
  const _Achievements({required this.items});
  final List<Achievement> items;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Achievements', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      if (items.isEmpty)
        const _Empty(
          icon: Icons.emoji_events_outlined,
          text: 'Your active GOLD badges will appear here.',
        )
      else
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map(
                (item) => Chip(
                  avatar: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.amber,
                  ),
                  label: Text(
                    '${_achievementLabel(item.type)} · ${item.earnedAt.toLocal().toIso8601String().substring(0, 10)}',
                  ),
                ),
              )
              .toList(),
        ),
    ],
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        Icon(icon),
        const SizedBox(height: 8),
        Text(text, textAlign: TextAlign.center),
      ],
    ),
  );
}

class _InlineFailure extends StatelessWidget {
  const _InlineFailure({required this.state});
  final PointsState state;
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.errorContainer,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(child: Text(state.partialFailure!.message)),
          if (state.partialFailure!.requestId != null)
            IconButton(
              tooltip: 'Support details',
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Support details'),
                  content: SelectableText(
                    'Request ID: ${state.partialFailure!.requestId}',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
              icon: const Icon(Icons.info_outline),
            ),
        ],
      ),
    ),
  );
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: context.read<PointsCubit>().load,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

class _PerformanceSkeleton extends StatelessWidget {
  const _PerformanceSkeleton();
  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('performance-loading-skeleton'),
    padding: const EdgeInsets.all(16),
    children: List.generate(
      5,
      (index) => Container(
        height: index == 0 ? 170 : 110,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(22),
        ),
      ),
    ),
  );
}

Future<void> _confirmRedemption(
  BuildContext context,
  PointsWallet wallet,
) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compensate 1 RED?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text('Exact cost: ${wallet.greenCostPerRed} GREEN'),
            Text(
              'Estimated remaining balance: ${wallet.green.available - wallet.greenCostPerRed} GREEN',
            ),
            const SizedBox(height: 6),
            const Text(
              'Your wallet will refresh from the server after confirmation.',
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('confirm-redemption'),
                    onPressed: () => Navigator.pop(sheetContext, true),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  if (confirmed == true && context.mounted) {
    await context.read<PointsCubit>().redeem(1);
  }
}

void _showDay(
  BuildContext context,
  PerformanceDay day,
  String timezone,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) {
    return SafeArea(
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
                _statusIcon(day.status),
                color: _statusColor(context, day.status),
              ),
              title: Text(_statusLabel(day.status)),
              subtitle: day.status == PerformanceStatus.pending
                  ? const Text(
                      'This day is unresolved. It is not recorded as an absence.',
                    )
                  : null,
            ),
            if (day.templateName != null) _Detail('Shift', day.templateName!),
            _Detail('Clock in', WorkspaceTime.time(day.clockInAt, timezone)),
            _Detail('Clock out', WorkspaceTime.time(day.clockOutAt, timezone)),
            if (day.workDurationMinutes != null)
              _Detail('Worked', '${day.workDurationMinutes} minutes'),
            if (day.lateMinutes != null)
              _Detail('Late', '${day.lateMinutes} minutes'),
            if (day.extraEffort) const _Detail('Extra effort', 'Recognized'),
            if (day.pointChanges.isNotEmpty) ...[
              const Divider(),
              Text(
                'Point changes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ...day.pointChanges.map(
                (change) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_pointIcon(change.type)),
                  title: Text(_pointLabel(change.type)),
                  trailing: Text(
                    '${change.amount > 0 ? '+' : ''}${change.amount}',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  },
);

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

String _monthLabel(DateTime value) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[value.month - 1]} ${value.year}';
}

String _domainMessage(String code) => switch (code) {
  'POINTS_INSUFFICIENT_GREEN' => 'You do not have enough GREEN points.',
  'POINTS_INSUFFICIENT_RED' => 'There is no active RED point to compensate.',
  'POINTS_REDEMPTION_CONFLICT' =>
    'This redemption conflicts with an earlier request. Refresh and try again.',
  'POINTS_POLICY_DISABLED' || 'POINTS_COMPENSATION_DISABLED' =>
    'Redemption is currently disabled for this workspace.',
  'POINTS_BALANCE_INVARIANT_VIOLATION' =>
    'Your balance needs support review before redemption.',
  _ => 'Redemption could not be completed.',
};
String _pointLabel(PointType type) => switch (type) {
  PointType.green => 'GREEN',
  PointType.black => 'BLACK',
  PointType.red => 'RED',
  PointType.orange => 'ORANGE',
  PointType.blue => 'BLUE',
  PointType.unknown => 'Points',
};
IconData _pointIcon(PointType type) => switch (type) {
  PointType.green => Icons.eco,
  PointType.black => Icons.timelapse,
  PointType.red => Icons.error_outline,
  PointType.orange => Icons.pending_actions,
  PointType.blue => Icons.volunteer_activism,
  PointType.unknown => Icons.help_outline,
};
String _reason(String value) => value
    .toLowerCase()
    .split('_')
    .map(
      (part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}',
    )
    .join(' ');
String _statusLabel(PerformanceStatus? status) => switch (status) {
  PerformanceStatus.present => 'Present',
  PerformanceStatus.late => 'Late',
  PerformanceStatus.absent => 'Absent',
  PerformanceStatus.incomplete => 'Incomplete',
  PerformanceStatus.excused => 'Excused',
  PerformanceStatus.dayOff => 'Day off',
  PerformanceStatus.pending => 'Pending',
  PerformanceStatus.unknown => 'Unknown',
  null => 'No status',
};
IconData _statusIcon(PerformanceStatus status) => switch (status) {
  PerformanceStatus.present => Icons.check_circle_outline,
  PerformanceStatus.late => Icons.schedule,
  PerformanceStatus.absent => Icons.cancel_outlined,
  PerformanceStatus.incomplete => Icons.timelapse,
  PerformanceStatus.excused => Icons.favorite_outline,
  PerformanceStatus.dayOff => Icons.weekend_outlined,
  PerformanceStatus.pending => Icons.more_time,
  PerformanceStatus.unknown => Icons.help_outline,
};
Color _statusColor(BuildContext context, PerformanceStatus? status) =>
    switch (status) {
      PerformanceStatus.present => Colors.green,
      PerformanceStatus.late => Colors.orange,
      PerformanceStatus.absent => Theme.of(context).colorScheme.error,
      PerformanceStatus.incomplete => Colors.deepOrange,
      PerformanceStatus.excused => Colors.purple,
      PerformanceStatus.dayOff => Colors.blueGrey,
      PerformanceStatus.pending ||
      PerformanceStatus.unknown ||
      null => Theme.of(context).colorScheme.outline,
    };
String _achievementLabel(AchievementType type) => switch (type) {
  AchievementType.perfectWeek => 'Perfect week',
  AchievementType.onTime10 => 'On time ×10',
  AchievementType.reliability30Days => '30-day reliability',
  AchievementType.teamSupporter => 'Team supporter',
  AchievementType.nightShiftHero => 'Night shift hero',
  AchievementType.zeroAbsenceMonth => 'Zero absence month',
  AchievementType.unknown => 'Achievement',
};
