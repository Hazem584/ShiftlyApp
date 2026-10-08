import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/features/points/presentation/cubit/points_cubit.dart';
import 'package:shiftly/features/points/presentation/widgets/points_achievements.dart';
import 'package:shiftly/features/points/presentation/widgets/points_calendar.dart';
import 'package:shiftly/features/points/presentation/widgets/points_failure_view.dart';
import 'package:shiftly/features/points/presentation/widgets/points_hero.dart';
import 'package:shiftly/features/points/presentation/widgets/points_history.dart';
import 'package:shiftly/features/points/presentation/widgets/points_inline_failure.dart';
import 'package:shiftly/features/points/presentation/widgets/points_loading_skeleton.dart';
import 'package:shiftly/features/points/presentation/widgets/points_redemption.dart';
import 'package:shiftly/features/points/presentation/widgets/points_wallet.dart';

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
      if (state.initialLoading) return const PointsLoadingSkeleton();
      final wallet = state.wallet;
      if (wallet == null) {
        return PointsFailureView(
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
                  PointsHero(wallet: wallet),
                  if (state.partialFailure != null) ...[
                    const SizedBox(height: 12),
                    PointsInlineFailure(state: state),
                  ],
                  const SizedBox(height: 20),
                  PointsWalletView(wallet: wallet),
                  const SizedBox(height: 20),
                  PointsRedemption(wallet: wallet, state: state),
                  const SizedBox(height: 24),
                  PointsCalendar(state: state),
                  const SizedBox(height: 24),
                  PointsHistory(state: state),
                  const SizedBox(height: 24),
                  PointsAchievements(
                    items: state.achievements,
                    timezone: wallet.timezone,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
