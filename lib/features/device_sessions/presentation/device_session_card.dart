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
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(
              device.deviceName == 'Unknown device'
                  ? c.tr('Unknown device')
                  : device.deviceName,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (device.osVersion.isNotEmpty) Text(device.osVersion),
                if (device.appVersion.isNotEmpty)
                  Text(
                    c.tr('App version: {version}', {
                      'version': device.appVersion,
                    }),
                  ),
                const SizedBox(height: 12),
                Text(
                  c.tr('Signed in: {date}', {'date': date(device.createdAt)}),
                ),
                Text(
                  c.tr('Last activity: {date}', {
                    'date': date(device.lastSeenAt),
                  }),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(c.tr('Close')),
              ),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.deviceName == 'Unknown device'
                          ? context.tr('Unknown device')
                          : device.deviceName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr('Last activity: {date}', {
                        'date': date(device.lastSeenAt),
                      }),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (device.isCurrent || device.isFirst)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (device.isCurrent)
                              Text(
                                context.tr('This device'),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (device.isFirst)
                              Text(
                                context.tr('Earliest active sign-in'),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('revoke-${device.id}'),
                onPressed: disabled ? null : onRevoke,
                tooltip: context.tr('Sign out this device'),
                icon: const Icon(Icons.logout, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
