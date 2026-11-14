import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/features/communication/presentation/communication_page.dart';
import 'package:shiftly/features/device_sessions/application/device_sessions_cubit.dart';
import 'package:shiftly/features/device_sessions/domain/device_sessions_repository.dart';
import 'package:shiftly/features/device_sessions/presentation/device_session_card.dart';

class DeviceSessionsView extends StatelessWidget {
  const DeviceSessionsView({super.key, required this.onCurrentSessionRevoked});
  final Future<void> Function() onCurrentSessionRevoked;

  Future<void> _revoke(BuildContext context, DeviceSession? target) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          context.tr(
            target == null ? 'Sign out all devices?' : 'Sign out this device?',
          ),
        ),
        content: Text(
          target == null
              ? context.tr(
                  'All devices, including this one, will need to sign in again.',
                )
              : context.tr('This device will need to sign in again: {device}', {
                  'device': target.deviceName == 'Unknown device'
                      ? context.tr('Unknown device')
                      : target.deviceName,
                }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('Sign out')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final current = await context.read<DeviceSessionsCubit>().revoke(target);
    if (current == true) await onCurrentSessionRevoked();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<DeviceSessionsCubit, DeviceSessionsState>(
    builder: (context, state) {
      final blocked = state.busy || state.loading;
      return CommunicationPage(
        title: 'Devices and sessions',
        footer: OutlinedButton.icon(
          key: const Key('logout-all-devices'),
          onPressed: blocked || state.items.isEmpty
              ? null
              : () => _revoke(context, null),
          icon: const Icon(Icons.logout),
          label: Text(context.tr('Sign out all devices')),
        ),
        child: RefreshIndicator(
          onRefresh: () => context.read<DeviceSessionsCubit>().load(),
          child: ListView(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (state.loading || state.busy)
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
                        Text(
                          context.tr(state.error!),
                          key: const Key('devices-error'),
                        ),
                        TextButton(
                          onPressed: blocked
                              ? null
                              : () =>
                                    context.read<DeviceSessionsCubit>().load(),
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
              ...state.items.map(
                (device) => DeviceSessionCard(
                  device: device,
                  disabled: blocked,
                  onRevoke: () => _revoke(context, device),
                ),
              ),
              if (state.hasNext)
                TextButton(
                  onPressed: blocked
                      ? null
                      : () => context.read<DeviceSessionsCubit>().load(
                          more: true,
                        ),
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
        ),
      );
    },
  );
}
