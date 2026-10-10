import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/features/points/presentation/cubit/points_cubit.dart';

class PerformanceThumbnail extends StatelessWidget {
  const PerformanceThumbnail({super.key});

  @override
  Widget build(BuildContext context) {
    PointsCubit? cubit;
    try {
      cubit = BlocProvider.of<PointsCubit>(context);
    } catch (_) {
      // Keeps independently composed dashboard widgets backwards compatible.
      return const SizedBox.shrink();
    }
    return BlocBuilder<PointsCubit, PointsState>(
      bloc: cubit,
      builder: (context, state) {
        final wallet = state.wallet;
        return Semantics(
          button: true,
          label: wallet == null
              ? context.tr('My Performance, loading')
              : context.tr(
                  'My Performance, {green} available GREEN, {red} active RED, {streak} day streak',
                  {
                    'green': '${wallet.green.available}',
                    'red': '${wallet.red.active}',
                    'streak': '${wallet.currentStreak}',
                  },
                ),
          child: Card(
            key: const Key('performance-thumbnail'),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: InkWell(
              onTap: () => context.go('/employee?tab=performance'),
              child: Ink(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.ink, AppColors.inkMuted],
                  ),
                ),
                padding: const EdgeInsets.all(18),
                child: wallet == null
                    ? Row(
                        children: [
                          const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            context.tr('Loading My Performance…'),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.auto_graph_rounded,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  context.tr('My Performance'),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: Colors.white),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 18,
                            runSpacing: 10,
                            children: [
                              _metric(
                                context,
                                '${wallet.green.available}',
                                'GREEN',
                              ),
                              _metric(
                                context,
                                '${wallet.red.active}',
                                'Active RED',
                              ),
                              _metric(
                                context,
                                '${wallet.currentStreak}',
                                'Day streak',
                              ),
                              if (wallet.greenNeededForOneRed > 0)
                                _metric(
                                  context,
                                  '${wallet.greenNeededForOneRed}',
                                  'GREEN to compensate',
                                ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Widget _metric(BuildContext context, String value, String label) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  children: [
    Text(
      value,
      style: Theme.of(context).textTheme.titleLarge
          ?.copyWith(color: Colors.white),
    ),
    Text(
      label,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: Colors.white70),
    ),
  ],
);
