import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
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
          Expanded(child: Text(context.tr(state.partialFailure!.message))),
          if (state.partialFailure!.requestId != null)
            IconButton(
              tooltip: context.tr('Support details'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(context.tr('Support details')),
                  content: SelectableText(
                    context.tr('Request ID: {value1}', {
                      'value1': (state.partialFailure!.requestId).toString(),
                    }),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(context.tr('Close')),
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
