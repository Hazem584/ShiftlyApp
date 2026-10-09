import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';

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
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: narrow ? 10 : 16,
        vertical: 8,
      ),
      leading: CircleAvatar(
        backgroundColor: AppColors.orangeSoft,
        foregroundColor: AppColors.orange,
        child: Text(group.name.characters.first.toUpperCase()),
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
          if (group.lastMessage != null)
            Text(
              group.lastMessage!.text ?? group.lastMessage!.type.toLowerCase(),
              maxLines: narrow ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          Text(
            '${group.memberCount} members',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (group.lastMessage != null)
            Text(
              WorkspaceTime.time(
                group.lastMessage!.createdAt,
                context.read<ChatGroupsCubit>().scope?.timezone ?? 'Etc/UTC',
                locale: Localizations.localeOf(context).toString(),
              ),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          if (group.unreadCount > 0)
            Badge(
              label: Text(
                group.unreadCount > 99 ? '99+' : '${group.unreadCount}',
              ),
            ),
        ],
      ),
    ),
  );
}
