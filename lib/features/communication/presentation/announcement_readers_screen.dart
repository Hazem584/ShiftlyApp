import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';

import 'announcement_recipient_screen.dart';
import 'communication_actions.dart';
import 'communication_page.dart';

class AnnouncementReadersScreen extends StatefulWidget {
  const AnnouncementReadersScreen({
    required this.item,
    required this.repository,
    required this.workspaceId,
    required this.timezone,
    super.key,
  });
  final TeamAnnouncement item;
  final TeamWorkRepository repository;
  final String workspaceId, timezone;
  @override
  State<AnnouncementReadersScreen> createState() =>
      _AnnouncementReadersScreenState();
}

class _AnnouncementReadersScreenState extends State<AnnouncementReadersScreen> {
  late Future<List<AnnouncementReader>> _future = widget.repository.readers(
    widget.workspaceId,
    widget.item.id,
  );
  @override
  Widget build(BuildContext context) => CommunicationPage(
    title: 'Recipient progress',
    child: FutureBuilder<List<AnnouncementReader>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(context.tr(ApiErrorParser.parse(snapshot.error!).message)),
              TextButton(
                onPressed: () => setState(
                  () => _future = widget.repository.readers(
                    widget.workspaceId,
                    widget.item.id,
                  ),
                ),
                child: Text(context.tr('Retry')),
              ),
            ],
          );
        }
        if (!snapshot.hasData) return const AppContentLoading();
        final rows = snapshot.data!,
            read = rows.where((r) => r.readAt != null).length,
            ack = rows.where((r) => r.acknowledgedAt != null).length;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              widget.item.title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
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
                      announcementTitle: widget.item.title,
                      timezone: widget.timezone,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    ),
  );
}
