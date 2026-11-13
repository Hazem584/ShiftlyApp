import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

class ChatConversationHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const ChatConversationHeader({
    required this.group,
    required this.manager,
    required this.onInformation,
    required this.onSearch,
    required this.onPinned,
    required this.onMembers,
    required this.onEdit,
    required this.onArchive,
    super.key,
  });
  final ChatGroup? group;
  final bool manager;
  final VoidCallback onInformation,
      onSearch,
      onPinned,
      onMembers,
      onEdit,
      onArchive;
  @override
  Size get preferredSize => const Size.fromHeight(65);
  @override
  Widget build(BuildContext context) {
    final g = group;
    final name = g?.name ?? context.tr('Chat');
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w.characters.first.toUpperCase())
        .join();
    return AppBar(
      toolbarHeight: 64,
      titleSpacing: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      title: InkWell(
        onTap: g == null ? null : onInformation,
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (g != null)
                    Text(
                      context.tr('{value1} members', {
                        'value1': '${g.memberCount}',
                      }),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          tooltip: context.tr('Conversation options'),
          onSelected: (value) {
            switch (value) {
              case 'information':
                onInformation();
              case 'search':
                onSearch();
              case 'pinned':
                onPinned();
              case 'members':
                onMembers();
              case 'edit':
                onEdit();
              case 'archive':
                onArchive();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'information',
              enabled: g != null,
              child: Text(context.tr('Group information')),
            ),
            PopupMenuItem(
              value: 'search',
              child: Text(context.tr('Search conversation')),
            ),
            PopupMenuItem(
              value: 'pinned',
              child: Text(context.tr('Pinned messages')),
            ),
            PopupMenuItem(
              value: 'members',
              enabled: g != null,
              child: Text(context.tr('Group members')),
            ),
            if (manager && g != null && !g.isArchived) ...[
              PopupMenuItem(
                value: 'edit',
                child: Text(context.tr('Edit group')),
              ),
              PopupMenuItem(
                value: 'archive',
                child: Text(context.tr('Archive group')),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
