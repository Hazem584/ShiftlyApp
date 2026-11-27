import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/services/chat_message_summary.dart';

import 'chat_group_tile_activity.dart';

class ChatGroupTile extends StatelessWidget {
  const ChatGroupTile({
    super.key,
    required this.group,
    required this.narrow,
    required this.onTap,
  });
  final ChatGroup group;
  final bool narrow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final summary = chatMessageSummary(group.lastMessage);
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(
          horizontal: narrow ? 10 : 16,
          vertical: 6,
        ),
        leading: CircleAvatar(
          backgroundColor: AppPalette.of(context).selected,
          foregroundColor: AppPalette.of(context).primaryColor,
          child: Text(
            group.name
                .trim()
                .split(RegExp(r'\s+'))
                .where((w) => w.isNotEmpty)
                .take(2)
                .map((w) => w.characters.first.toUpperCase())
                .join(),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                group.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (group.isArchived)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.archive_outlined, size: 18),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary.text ?? context.tr(summary.label),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              context.tr('{value1} members', {
                'value1': (group.memberCount).toString(),
              }),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        trailing: ChatGroupTileActivity(group: group),
      ),
    );
  }
}
