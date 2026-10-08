import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
              ? 'My Performance, loading'
              : 'My Performance, ${wallet.green.available} available GREEN, '
                    '${wallet.red.active} active RED, '
                    '${wallet.currentStreak} day streak',
          child: Card(
            key: const Key('performance-thumbnail'),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: InkWell(
              onTap: () => context.go('/employee?tab=performance'),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(18),
                child: wallet == null
                    ? const Row(
                        children: [
                          SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Loading My Performance…'),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_graph_rounded),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'My Performance',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ),
                              const Icon(Icons.arrow_forward_rounded),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 18,
                            runSpacing: 10,
                            children: [
                              _metric(context, '${wallet.green.available}', 'GREEN'),
                              _metric(context, '${wallet.red.active}', 'Active RED'),
                              _metric(context, '${wallet.currentStreak}', 'Day streak'),
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
      Text(value, style: Theme.of(context).textTheme.titleLarge),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
