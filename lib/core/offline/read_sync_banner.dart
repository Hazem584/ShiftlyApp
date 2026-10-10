import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/utils/workspace_time.dart';

import 'read_sync_cubit.dart';
import 'read_sync_state.dart';

class ReadSyncBanner extends StatelessWidget {
  const ReadSyncBanner({
    required this.category,
    required this.onRefresh,
    super.key,
  });
  final ReadCategory category;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReadSyncCubit?>();
    if (cubit == null) return const SizedBox.shrink();
    return BlocBuilder<ReadSyncCubit, ReadSyncState>(
      bloc: cubit,
      builder: (context, state) {
        final status = state.statuses[category];
        if (status == null) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        final timezone =
            context
                .read<SessionCoordinator?>()
                ?.state
                .activeMembership
                ?.workspace
                .timezone ??
            'Etc/UTC';
        final locale = AppLocalizations.of(context).locale.languageCode;
        final label = status.pending > 0
            ? 'Updating…'
            : status.usingSaved
            ? 'Showing saved data'
            : status.failed
            ? 'Could not update'
            : 'Up to date';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: status.usingSaved || status.failed
                  ? scheme.secondaryContainer
                  : scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    status.pending > 0
                        ? Icons.sync
                        : status.usingSaved || status.failed
                        ? Icons.cloud_off_outlined
                        : Icons.cloud_done_outlined,
                    color: scheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(label),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        if (status.updatedAt != null)
                          Text(
                            context.tr('Last updated: {time}', {
                              'time': WorkspaceTime.dateTime(
                                status.updatedAt!,
                                timezone,
                                locale: locale,
                              ),
                            }),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (status.usingSaved)
                          Text(
                            context.tr(
                              'Connect and refresh for the latest changes. Attendance requires an internet connection.',
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: context.tr('Refresh'),
                    onPressed: status.pending > 0 ? null : onRefresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
