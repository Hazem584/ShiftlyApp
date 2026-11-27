import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/features/communication/presentation/announcement_readers_list.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';

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
        return buildAnnouncementReadersList(
          context,
          announcementTitle: widget.item.title,
          timezone: widget.timezone,
          rows: snapshot.data!,
        );
      },
    ),
  );
}
