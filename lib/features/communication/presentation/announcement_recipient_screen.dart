import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';

import 'communication_page.dart';

class AnnouncementRecipientScreen extends StatelessWidget {
  const AnnouncementRecipientScreen({
    required this.reader,
    required this.announcementTitle,
    required this.timezone,
    super.key,
  });
  final AnnouncementReader reader;
  final String announcementTitle, timezone;
  @override
  Widget build(BuildContext context) => CommunicationPage(
    title: reader.name,
    localizeTitle: false,
    footer: FilledButton(
      onPressed: () => Navigator.pop(context),
      child: Text(context.tr('Back to recipient progress')),
    ),
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(announcementTitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        for (final item in [
          ('Read', reader.readAt),
          ('Acknowledged', reader.acknowledgedAt),
        ]) ...[
          Card(
            child: ListTile(
              leading: Icon(
                item.$2 == null ? Icons.schedule : Icons.check_circle_outline,
              ),
              title: Text(context.tr(item.$1)),
              subtitle: Text(
                item.$2 == null
                    ? context.tr('Not yet')
                    : WorkspaceTime.dateTime(
                        item.$2!,
                        timezone,
                        locale: Localizations.localeOf(context).toString(),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Text(context.tr('Read and acknowledgment are recorded separately.')),
      ],
    ),
  );
}
