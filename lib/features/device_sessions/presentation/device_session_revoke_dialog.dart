import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/device_sessions/domain/device_sessions_repository.dart';

Future<bool?> showRevokeDeviceSessionDialog(
  BuildContext context,
  DeviceSession? target,
) => showDialog<bool>(
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
