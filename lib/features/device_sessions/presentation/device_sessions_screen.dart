import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/device_sessions/application/device_sessions_cubit.dart';
import 'package:shiftly/features/device_sessions/domain/device_sessions_repository.dart';

class DeviceSessionsScreen extends StatelessWidget {
  const DeviceSessionsScreen({
    super.key,
    this.repository,
    required this.onCurrentSessionRevoked,
  });
  final DeviceSessionsRepository? repository;
  final Future<void> Function() onCurrentSessionRevoked;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => DeviceSessionsCubit(
      repository ?? context.read<DeviceSessionsRepository>(),
    )..load(),
    child: _DeviceSessionsView(
      onCurrentSessionRevoked: onCurrentSessionRevoked,
    ),
  );
}

class _DeviceSessionsView extends StatelessWidget {
  const _DeviceSessionsView({required this.onCurrentSessionRevoked});
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('Devices and sessions'))),
    body: BlocBuilder<DeviceSessionsCubit, DeviceSessionsState>(
      builder: (context, state) {
        final blocked = state.busy || state.loading;
        return RefreshIndicator(
          onRefresh: () => context.read<DeviceSessionsCubit>().load(),
          child: ListView(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Text(
                context.tr(
                  'You can use your account on multiple devices. Manage each sign-in below.',
                ),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              Text(
                context.tr(
                  'Devices are listed from the earliest active sign-in. Device details may be unavailable for older app versions.',
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                key: const Key('logout-all-devices'),
                onPressed: blocked || state.items.isEmpty
                    ? null
                    : () => _revoke(context, null),
                icon: const Icon(Icons.logout),
                label: Text(context.tr('Sign out all devices')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
              if (state.loading || state.busy)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
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
                (device) => _DeviceCard(
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
            ],
          ),
        );
      },
    ),
  );
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.device,
    required this.disabled,
    required this.onRevoke,
  });
  final DeviceSession device;
  final bool disabled;
  final VoidCallback onRevoke;
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    String date(DateTime value) =>
        DateFormat.yMMMd(locale).add_jm().format(value.toLocal());
    final icon = switch (device.platform) {
      'android' || 'ios' => Icons.smartphone,
      'web' => Icons.public,
      _ => Icons.computer,
    };
    return Card(
      key: ValueKey('device-${device.id}'),
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    device.deviceName == 'Unknown device'
                        ? context.tr('Unknown device')
                        : device.deviceName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (device.isCurrent || device.isFirst)
              Wrap(
                spacing: 8,
                children: [
                  if (device.isCurrent)
                    Chip(label: Text(context.tr('This device'))),
                  if (device.isFirst)
                    Chip(label: Text(context.tr('Earliest active sign-in'))),
                ],
              ),
            if (device.osVersion.isNotEmpty) Text(device.osVersion),
            if (device.appVersion.isNotEmpty)
              Text(
                context.tr('App version: {version}', {
                  'version': device.appVersion,
                }),
              ),
            const SizedBox(height: 8),
            Text(
              context.tr('Signed in: {date}', {'date': date(device.createdAt)}),
            ),
            Text(
              context.tr('Last activity: {date}', {
                'date': date(device.lastSeenAt),
              }),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              key: ValueKey('revoke-${device.id}'),
              onPressed: disabled ? null : onRevoke,
              icon: const Icon(Icons.logout, size: 18),
              label: Text(context.tr('Sign out this device')),
            ),
          ],
        ),
      ),
    );
  }
}
