import 'package:flutter/material.dart';
import 'package:shiftly/features/points/data/points_models.dart';

class PointsWalletView extends StatelessWidget {
  const PointsWalletView({required this.wallet, super.key});
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
              _balanceCard(context, 'GREEN available', wallet.green.available, Icons.eco, Colors.green, width),
              _balanceCard(context, 'Active RED', wallet.red.active, Icons.error_outline, Colors.red, width),
              _balanceCard(context, 'BLACK this month', wallet.black.currentMonth, Icons.timelapse, Colors.blueGrey, width),
              _balanceCard(context, 'ORANGE', wallet.orange.total, Icons.pending_actions, Colors.orange, width),
              _balanceCard(context, 'BLUE', wallet.blue.total, Icons.volunteer_activism, Colors.blue, width),
            ],
          );
        },
      ),
    ],
  );
}

Widget _balanceCard(BuildContext context, String label, int value, IconData icon, Color color, double width) =>
    Semantics(
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
