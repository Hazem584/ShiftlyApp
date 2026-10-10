import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/points/domain/entities/points_models.dart';
import 'package:shiftly/features/points/presentation/cubit/points_cubit.dart';

class PointsRedemption extends StatelessWidget {
  const PointsRedemption({
    required this.wallet,
    required this.state,
    super.key,
  });
  final PointsWallet wallet;
  final PointsState state;

  @override
  Widget build(BuildContext context) {
    final eligible =
        wallet.maxRedeemable > 0 &&
        !state.redeeming &&
        !state.hasUnresolvedRedemption;
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
                    : () => context.read<PointsCubit>().redeem(
                        state.unresolvedRedPoints,
                        retry: true,
                      ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry same redemption'),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('redeem-red-button'),
                onPressed: eligible ? () => _confirm(context, wallet) : null,
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

Future<void> _confirm(BuildContext context, PointsWallet wallet) async {
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
                    child: Text(context.tr('Cancel')),
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

String _domainMessage(String code) => switch (code) {
  'POINTS_INSUFFICIENT_GREEN' => 'You do not have enough GREEN points.',
  'POINTS_INSUFFICIENT_RED' => 'There is no active RED point to compensate.',
  'POINTS_REDEMPTION_CONFLICT' => 'The saved redemption conflicts with the server record. Keep this recovery key and contact support.',
  'POINTS_POLICY_DISABLED' || 'POINTS_COMPENSATION_DISABLED' =>
    'Redemption is currently disabled for this workspace.',
  'POINTS_BALANCE_INVARIANT_VIOLATION' =>
    'Your balance needs support review before redemption.',
  _ => 'Redemption could not be completed.',
};
