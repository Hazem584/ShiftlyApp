import 'package:flutter/material.dart';
import 'package:shiftly/features/points/presentation/cubit/points_cubit.dart';

class PointsInlineFailure extends StatelessWidget {
  const PointsInlineFailure({required this.state, super.key});
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
