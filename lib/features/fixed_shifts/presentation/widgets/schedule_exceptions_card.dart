import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/schedule_exception.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/schedule_exception_item_view.dart';

Widget buildScheduleExceptionsCard({
  required BuildContext context,
  required String? employeeMembershipId,
  required String timezone,
  required bool canEdit,
  required bool busy,
  required bool loading,
  required bool more,
  required String? error,
  required List<ScheduleException> records,
  required VoidCallback onCreate,
  required VoidCallback onRefresh,
  required VoidCallback onLoadMore,
  required ValueChanged<ScheduleException> onCancel,
}) {
  final disabled = busy || loading;
  return SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr(
            employeeMembershipId == null
                ? 'Workspace holidays'
                : 'Schedule exceptions and holidays',
          ),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          context.tr(
            'Employee instructions take priority over a workspace holiday. The weekly assignment stays the same.',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            if (canEdit)
              OutlinedButton.icon(
                onPressed: disabled ? null : onCreate,
                icon: const Icon(Icons.event_note_outlined),
                label: Text(
                  context.tr(
                    employeeMembershipId == null
                        ? 'Add workspace holiday'
                        : 'Add day exception',
                  ),
                ),
              ),
            IconButton(
              onPressed: disabled ? null : onRefresh,
              tooltip: context.tr('Refresh'),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        if (error != null)
          Text(
            context.tr(error),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (loading) const AppContentLoading(rows: 1),
        if (!loading && records.isEmpty && error == null)
          Text(context.tr('No schedule exceptions yet.')),
        for (final entry in records)
          buildScheduleExceptionItem(
            context: context,
            entry: entry,
            timezone: timezone,
            employeeMembershipId: employeeMembershipId,
            canEdit: canEdit,
            disabled: disabled,
            onCancel: () => onCancel(entry),
          ),
        if (more)
          TextButton(
            onPressed: disabled ? null : onLoadMore,
            child: Text(context.tr('Load more')),
          ),
      ],
    ),
  );
}
