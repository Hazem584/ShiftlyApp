import 'package:flutter/material.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/points/data/points_models.dart';
import 'package:shiftly/features/points/presentation/widgets/points_empty.dart';

class PointsAchievements extends StatelessWidget {
  const PointsAchievements({
    required this.items,
    required this.timezone,
    this.emptyText = 'Your active GOLD badges will appear here.',
    super.key,
  });
  final List<Achievement> items;
  final String timezone;
  final String emptyText;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Achievements', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      if (items.isEmpty)
        PointsEmpty(
          icon: Icons.emoji_events_outlined,
          text: emptyText,
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
                    '${_achievementLabel(item.type)} · ${WorkspaceTime.dateKey(item.earnedAt, timezone)}',
                  ),
                ),
              )
              .toList(),
        ),
    ],
  );
}

String _achievementLabel(AchievementType type) => switch (type) {
  AchievementType.perfectWeek => 'Perfect week',
  AchievementType.onTime10 => 'On time ×10',
  AchievementType.reliability30Days => '30-day reliability',
  AchievementType.teamSupporter => 'Team supporter',
  AchievementType.nightShiftHero => 'Night shift hero',
  AchievementType.zeroAbsenceMonth => 'Zero absence month',
  AchievementType.unknown => 'Achievement',
};
