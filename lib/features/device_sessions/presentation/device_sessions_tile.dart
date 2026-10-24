import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class DeviceSessionsTile extends StatelessWidget {
  const DeviceSessionsTile({super.key});
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      key: const Key('devices-settings'),
      leading: const Icon(Icons.devices),
      title: Text(context.tr('Devices and sessions')),
      subtitle: Text(
        context.tr('Manage the devices signed in to your account'),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/devices'),
    ),
  );
}
