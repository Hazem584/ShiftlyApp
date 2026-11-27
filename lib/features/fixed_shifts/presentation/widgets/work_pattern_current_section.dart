import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/utils/saved_schedule_formatter.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/weekday_row.dart';

List<Widget> buildWorkPatternCurrentSection(
  BuildContext context,
  WorkPatternState state,
) => [
  Row(
    children: [
      const Icon(Icons.calendar_view_week_outlined),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          context.tr('Work pattern'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      IconButton(
        tooltip: context.tr('Refresh work pattern'),
        onPressed: () => context.read<WorkPatternCubit>().load(retain: true),
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
  ),
  if (state.loading) const AppContentLoading(rows: 1),
  const SizedBox(height: 8),
  if (state.failure != null) ...[
    Text(
      context.tr(state.failure!.message),
      style: TextStyle(color: AppPalette.of(context).error),
    ),
    if (state.failure!.requestId != null)
      Text(
        context.tr('Support reference: {value1}', {
          'value1': state.failure!.requestId.toString(),
        }),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    const SizedBox(height: 8),
  ],
  if (state.history?.current case final current?) ...[
    Text(
      context.tr('Current schedule'),
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    const SizedBox(height: 6),
    Text(
      current.assignmentSnapshot != null
          ? savedScheduleLabel(context, current.assignmentSnapshot!)
          : context.tr('Historical assignment evidence is not recorded.'),
    ),
    WeekdayRow(days: current.expectedWeekdays),
    const SizedBox(height: 5),
    Text(
      context.tr('Effective {value1}{value2}', {
        'value1': current.effectiveFrom,
        'value2': current.effectiveTo == null
            ? ''
            : context.tr(' through {date}', {'date': '${current.effectiveTo}'}),
      }),
      style: Theme.of(context).textTheme.bodySmall,
    ),
  ] else
    Text(context.tr('No work pattern is currently effective.')),
];

List<Widget> buildWorkPatternFooterSection({
  required BuildContext context,
  required WorkPatternState state,
  required String timezone,
  required bool canEdit,
  required VoidCallback onReplace,
}) => [
  const SizedBox(height: 10),
  SizedBox(
    width: double.infinity,
    child: FilledButton.tonalIcon(
      key: const Key('replace-work-pattern'),
      onPressed:
          !canEdit ||
              state.saving ||
              state.loading ||
              !WorkspaceTime.isValid(timezone)
          ? null
          : onReplace,
      icon: state.saving
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.edit_calendar_outlined),
      label: Text(
        canEdit
            ? context.tr('Schedule a new version')
            : context.tr('Employee is inactive'),
      ),
    ),
  ),
  if (!WorkspaceTime.isValid(timezone))
    Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        context.tr(
          'The workspace timezone is invalid. Pattern changes are disabled.',
        ),
        style: TextStyle(color: AppPalette.of(context).error),
      ),
    ),
];
