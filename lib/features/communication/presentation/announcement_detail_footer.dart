import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/communication/presentation/announcement_readers_screen.dart';
import 'package:shiftly/features/communication/presentation/communication_actions.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';

Widget buildAnnouncementDetailFooter(
  BuildContext context, {
  required TeamAnnouncement item,
  required TeamWorkRepository repository,
  required String workspaceId,
  required String timezone,
  required bool manager,
  required bool busy,
  required bool read,
  required bool acknowledged,
  required VoidCallback onAcknowledge,
}) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    if (item.requiresAcknowledgment && !acknowledged)
      FilledButton(
        key: const Key('acknowledge-announcement'),
        onPressed: busy || !read ? null : onAcknowledge,
        child: Text(context.tr('Acknowledge update')),
      )
    else
      FilledButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.tr('Back to announcements')),
      ),
    if (manager)
      TextButton(
        key: const Key('announcement-recipient-progress'),
        onPressed: busy
            ? null
            : () => openCommunicationPage(
                context,
                AnnouncementReadersScreen(
                  item: item,
                  repository: repository,
                  workspaceId: workspaceId,
                  timezone: timezone,
                ),
              ),
        child: Text(context.tr('Recipient progress')),
      ),
  ],
);
