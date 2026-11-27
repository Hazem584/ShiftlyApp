import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/communication/presentation/announcement_recipient_screen.dart';
import 'package:shiftly/features/communication/presentation/communication_actions.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';

Widget buildAnnouncementReadersList(
  BuildContext context, {
  required String announcementTitle,
  required String timezone,
  required List<AnnouncementReader> rows,
}) {
  final read = rows.where((r) => r.readAt != null).length;
  final ack = rows.where((r) => r.acknowledgedAt != null).length;
  return ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text(announcementTitle, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 24),
      for (final value in [
        (read, '{count} of {total} read'),
        (ack, '{count} of {total} acknowledged'),
      ]) ...[
        Text(
          context.tr(value.$2, {
            'count': '${value.$1}',
            'total': '${rows.length}',
          }),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: rows.isEmpty ? 0 : value.$1 / rows.length,
        ),
        const SizedBox(height: 24),
      ],
      if (rows.isEmpty) Text(context.tr('No recipient activity yet.')),
      for (final reader in rows) ...[
        Card(
          child: ListTile(
            title: Text(reader.name),
            leading: Icon(
              reader.acknowledgedAt != null
                  ? Icons.verified_outlined
                  : reader.readAt != null
                  ? Icons.done_all
                  : Icons.schedule,
            ),
            subtitle: Text(
              context.tr(
                reader.acknowledgedAt != null
                    ? 'Acknowledged'
                    : reader.readAt != null
                    ? 'Read · Not acknowledged'
                    : 'Not read yet',
              ),
            ),
            onTap: () => openCommunicationPage(
              context,
              AnnouncementRecipientScreen(
                reader: reader,
                announcementTitle: announcementTitle,
                timezone: timezone,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    ],
  );
}
