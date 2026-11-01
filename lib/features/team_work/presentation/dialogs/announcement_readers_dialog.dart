import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';

class AnnouncementReadersDialog extends StatefulWidget {
  const AnnouncementReadersDialog({
    required this.repository,
    required this.workspaceId,
    required this.announcementId,
    required this.timezone,
    super.key,
  });
  final TeamWorkRepository repository;
  final String workspaceId, announcementId, timezone;
  @override
  State<AnnouncementReadersDialog> createState() =>
      _AnnouncementReadersDialogState();
}

class _AnnouncementReadersDialogState extends State<AnnouncementReadersDialog> {
  late Future<List<AnnouncementReader>> _readers = widget.repository.readers(
    widget.workspaceId,
    widget.announcementId,
  );
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr('Recipient progress')),
    content: SizedBox(
      width: 540,
      height: MediaQuery.sizeOf(context).height * .55,
      child: FutureBuilder<List<AnnouncementReader>>(
        future: _readers,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(ApiErrorParser.parse(snapshot.error!).message),
                TextButton(
                  onPressed: () => setState(
                    () => _readers = widget.repository.readers(
                      widget.workspaceId,
                      widget.announcementId,
                    ),
                  ),
                  child: Text(context.tr('Retry')),
                ),
              ],
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data!;
          final rows = all.where(
            (r) => r.name.toLowerCase().contains(
              _search.text.trim().toLowerCase(),
            ),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr(
                  '{read} read · {confirmed} confirmed · {total} recipients',
                  {
                    'read': all
                        .where((r) => r.readAt != null)
                        .length
                        .toString(),
                    'confirmed': all
                        .where((r) => r.acknowledgedAt != null)
                        .length
                        .toString(),
                    'total': all.length.toString(),
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: context.tr('Search recipients'),
                  prefixIcon: const Icon(Icons.search_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    for (final reader in rows)
                      ListTile(
                        title: Text(reader.name),
                        subtitle: Text(
                          context.tr(
                            reader.acknowledgedAt != null
                                ? 'Acknowledged'
                                : reader.readAt != null
                                ? 'Read'
                                : 'Not read yet',
                          ),
                        ),
                        onTap: () => showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(reader.name),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${context.tr('Read')}: ${reader.readAt == null ? context.tr('Not read yet') : WorkspaceTime.dateTime(reader.readAt!, widget.timezone)}',
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '${context.tr('Acknowledged')}: ${reader.acknowledgedAt == null ? context.tr('Not acknowledged') : WorkspaceTime.dateTime(reader.acknowledgedAt!, widget.timezone)}',
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(context.tr('Close')),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.tr('Close')),
      ),
    ],
  );
}
