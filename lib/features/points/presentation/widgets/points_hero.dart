import 'package:flutter/material.dart';
import 'package:shiftly/features/points/data/points_models.dart';

class PointsHero extends StatelessWidget {
  const PointsHero({required this.wallet, super.key});
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
            _heroValue(
              context,
              '${wallet.green.available}',
              'Available GREEN',
              Icons.eco_rounded,
            ),
            _heroValue(
              context,
              '${wallet.currentStreak}',
              'Current streak',
              Icons.local_fire_department_rounded,
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _heroValue(
  BuildContext context,
  String value,
  String label,
  IconData icon,
) => Semantics(
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
