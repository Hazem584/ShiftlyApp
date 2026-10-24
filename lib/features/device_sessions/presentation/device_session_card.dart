import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/device_sessions/domain/device_sessions_repository.dart';

class DeviceSessionCard extends StatelessWidget {
  const DeviceSessionCard({
    super.key,
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
