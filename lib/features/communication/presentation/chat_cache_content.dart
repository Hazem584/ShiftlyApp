import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

const _cacheTypes = [
  (Icons.image_outlined, 'Images', 'Downloaded chat images'),
  (Icons.description_outlined, 'Documents', 'Saved chat attachments'),
  (Icons.graphic_eq, 'Audio', 'Downloaded voice messages'),
];

Widget buildChatCacheContent(
  BuildContext context, {
  required Future<int> sizeFuture,
  required String? error,
}) => ListView(
  padding: const EdgeInsets.all(24),
  children: [
    FutureBuilder<int>(
      future: sizeFuture,
      builder: (context, snapshot) => Text(
        snapshot.hasError
            ? context.tr('Cache size unavailable')
            : context.tr('{size} MB on this device', {
                'size': snapshot.hasData
                    ? (snapshot.data! / 1000000).toStringAsFixed(1)
                    : '—',
              }),
        style: Theme.of(context).textTheme.titleLarge,
      ),
    ),
    const SizedBox(height: 28),
    for (final item in _cacheTypes) ...[
      Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Icon(item.$1),
          title: Text(context.tr(item.$2)),
          subtitle: Text(context.tr(item.$3)),
        ),
      ),
      const SizedBox(height: 12),
    ],
    const SizedBox(height: 12),
    Text(
      context.tr(
        'Clear cached media to free space. Active files are retained; messages remain in your groups.',
      ),
    ),
    if (error != null)
      Text(
        context.tr(error),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
  ],
);
