import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/device_sessions/domain/device_sessions_repository.dart';
import 'package:shiftly/features/device_sessions/presentation/device_session_details_dialog.dart';

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
    String date(DateTime v) =>
        DateFormat.yMMMd(locale).add_jm().format(v.toLocal());
    final icon = switch (device.platform) {
      'android' || 'ios' => Icons.smartphone,
      'web' => Icons.public,
      _ => Icons.computer,
    };
    final name = device.deviceName == 'Unknown device'
        ? context.tr('Unknown device')
        : device.deviceName;
    final theme = Theme.of(context);
    return Card(
      key: ValueKey('device-${device.id}'),
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showDeviceSessionDetailsDialog(context, device, date),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      context.tr('Last activity: {date}', {
                        'date': date(device.lastSeenAt),
                      }),
                      style: theme.textTheme.bodySmall,
                    ),
                    if (device.isCurrent)
                      Text(
                        context.tr('This device'),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (device.isFirst)
                      Text(
                        context.tr('Earliest active sign-in'),
                        style: theme.textTheme.bodySmall,
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
