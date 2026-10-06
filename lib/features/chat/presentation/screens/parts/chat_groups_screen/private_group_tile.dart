part of '../../chat_groups_screen.dart';

class _GroupTile extends StatelessWidget {
  const _GroupTile({
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
        vertical: 6,
      ),
      leading: CircleAvatar(
        child: Text(group.name.characters.first.toUpperCase()),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              group.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
              MaterialLocalizations.of(context).formatTimeOfDay(
                TimeOfDay.fromDateTime(group.lastMessage!.createdAt.toLocal()),
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
