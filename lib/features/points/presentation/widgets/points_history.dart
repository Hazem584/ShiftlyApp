import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/points/presentation/cubit/points_cubit.dart';
import 'package:shiftly/features/points/presentation/widgets/points_empty.dart';
import 'package:shiftly/features/points/presentation/widgets/points_formatters.dart';

class PointsHistory extends StatelessWidget {
  const PointsHistory({required this.state, super.key});
  final PointsState state;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Recent activity', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      if (state.history.isEmpty)
        const PointsEmpty(icon: Icons.receipt_long_outlined, text: 'No points activity yet.')
      else
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: state.history.map((entry) => ListTile(
              leading: CircleAvatar(child: Icon(pointIcon(entry.type))),
              title: Text(reasonLabel(entry.reason)),
              subtitle: Text(entry.operationalDate?.value ?? WorkspaceTime.dateTime(entry.createdAt, state.wallet!.timezone)),
              trailing: Text(
                '${entry.amount > 0 ? '+' : ''}${entry.amount} ${pointLabel(entry.type)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            )).toList(),
          ),
        ),
      if (state.hasMoreHistory)
        Center(
          child: TextButton(
            onPressed: state.loadingMoreHistory ? null : context.read<PointsCubit>().loadMoreHistory,
            child: Text(state.loadingMoreHistory ? 'Loading…' : 'Load more'),
          ),
        ),
    ],
  );
}
