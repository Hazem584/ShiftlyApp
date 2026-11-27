import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';

import 'work_pattern_history_tile.dart';

List<Widget> buildWorkPatternHistorySection(
  BuildContext context,
  WorkPatternState state,
  String timezone,
) {
  final history = state.history;
  if (history == null || history.history.isEmpty) return const [];
  final pagination = history.pagination;
  return [
    const Divider(height: 28),
    ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        context.tr('Version history ({value1})', {
          'value1': history.history.length.toString(),
        }),
      ),
      subtitle: Text(
        context.tr(
          'New patterns create versions; history is never overwritten.',
        ),
      ),
      children: [
        for (final pattern in history.history)
          WorkPatternHistoryTile(
            pattern: pattern,
            isCurrent: pattern.id == history.current?.id,
            timezone: timezone,
          ),
      ],
    ),
    if (pagination != null && pagination.totalPages > 1)
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: state.loading || pagination.page <= 1
                ? null
                : () => context.read<WorkPatternCubit>().load(
                    retain: true,
                    page: pagination.page - 1,
                  ),
            child: Text(context.tr('Previous')),
          ),
          Text(
            context.tr('Page {value1} of {value2}', {
              'value1': pagination.page.toString(),
              'value2': pagination.totalPages.toString(),
            }),
          ),
          TextButton(
            onPressed: state.loading || pagination.page >= pagination.totalPages
                ? null
                : () => context.read<WorkPatternCubit>().load(
                    retain: true,
                    page: pagination.page + 1,
                  ),
            child: Text(context.tr('Next')),
          ),
        ],
      ),
  ];
}
