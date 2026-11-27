import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/device_sessions/domain/device_sessions_repository.dart';

Future<void> showDeviceSessionDetailsDialog(
  BuildContext context,
  DeviceSession device,
  String Function(DateTime) date,
) => showDialog<void>(
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
          Text(c.tr('App version: {version}', {'version': device.appVersion})),
        const SizedBox(height: 12),
        Text(c.tr('Signed in: {date}', {'date': date(device.createdAt)})),
        Text(c.tr('Last activity: {date}', {'date': date(device.lastSeenAt)})),
      ],
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(c), child: Text(c.tr('Close'))),
    ],
  ),
);
