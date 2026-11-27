import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/flexible_attendance_eligibility_list.dart';

Widget buildFlexibleEligibilityCard(
  BuildContext context,
  FlexibleAttendanceState state,
  String timezone,
  Widget legacyReview,
) {
  final current = state.current;
  final entries = state.eligibility?.authorizedOccurrences ?? const [];
  return SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.legacyReviews.isNotEmpty) legacyReview,
        Row(
          children: [
            const Icon(Icons.bolt_rounded),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.tr('Clock in to a fixed shift'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: context.tr('Refresh eligibility'),
              onPressed: state.refreshing
                  ? null
                  : () => context.read<FlexibleAttendanceCubit>().load(
                      refresh: true,
                    ),
              icon: state.refreshing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        if (state.eligibility?.status == 'SHIFT_ASSIGNMENT_REQUIRED')
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              context.tr(
                'Ask your manager to assign your baseline fixed shift. Explicitly authorized extras remain optional.',
              ),
            ),
          ),
        if (state.eligibility?.openAttendanceId != null)
          Text(
            context.tr(
              'Attendance is already open. Refresh to restore it before another action.',
            ),
          ),
        if (current != null && !current.isOpen)
          Text(
            context.tr(
              'Attendance {value1} on {value2} is used and cannot be reopened.',
              {
                'value1': (current.occurrenceKind ?? 'historical').toString(),
                'value2': (current.operationalDate ?? 'unrecorded date')
                    .toString(),
              },
            ),
          ),
        if (entries.isEmpty)
          ...buildEmptyEligibilitySection(context, state)
        else
          ...buildEligibilityEntriesSection(context, state, entries, timezone),
      ],
    ),
  );
}
