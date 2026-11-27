import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/features/device_sessions/application/device_sessions_cubit.dart';
import 'package:shiftly/features/device_sessions/domain/device_sessions_repository.dart';
import 'package:shiftly/features/device_sessions/presentation/device_session_card.dart';

class DeviceSessionsList extends StatelessWidget {
  const DeviceSessionsList({
    required this.state,
    required this.blocked,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onRevoke,
    super.key,
  });
  final DeviceSessionsState state;
  final bool blocked;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final ValueChanged<DeviceSession> onRevoke;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView(
      padding: const EdgeInsets.all(20),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        if (blocked)
          const Padding(
            padding: EdgeInsets.all(20),
            child: AppContentLoading(),
          ),
        if (state.error != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(context.tr(state.error!), key: const Key('devices-error')),
                  TextButton(
                    onPressed: blocked ? null : onRefresh,
                    child: Text(context.tr('Retry')),
                  ),
                ],
              ),
            ),
          ),
        if (!state.loading && state.items.isEmpty && state.error == null)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(context.tr('No active sessions.')),
          ),
        for (final device in state.items)
          DeviceSessionCard(
            device: device,
            disabled: blocked,
            onRevoke: () => onRevoke(device),
          ),
        if (state.hasNext)
          TextButton(
            onPressed: blocked ? null : onLoadMore,
            child: Text(context.tr('Load more devices')),
          ),
        const SizedBox(height: 12),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              context.tr(
                'Revoke any session you no longer recognize. Tap a device to view its details.',
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
