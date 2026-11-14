import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/device_sessions/presentation/device_sessions_tile.dart';

import 'chat_cache_screen.dart';
import 'communication_actions.dart';
import 'communication_page.dart';

class DevicesStorageScreen extends StatelessWidget {
  const DevicesStorageScreen({super.key});
  @override
  Widget build(BuildContext context) => CommunicationPage(
    title: 'Devices and storage',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const DeviceSessionsTile(),
        const SizedBox(height: 14),
        Card(
          child: ListTile(
            key: const Key('chat-cache-settings'),
            leading: const Icon(Icons.storage_outlined),
            title: Text(context.tr('Chat cache')),
            subtitle: Text(
              context.tr('Downloaded images, documents and audio'),
            ),
            onTap: () =>
                openCommunicationPage(context, const ChatCacheScreen()),
          ),
        ),
      ],
    ),
  );
}
