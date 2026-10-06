part of '../../chat_screen.dart';

class _EditChatGroupDialog extends StatefulWidget {
  const _EditChatGroupDialog({
    required this.group,
    required this.groups,
    required this.onSuccess,
  });

  final ChatGroup group;
  final ChatGroupsCubit groups;
  final VoidCallback onSuccess;

  @override
  State<_EditChatGroupDialog> createState() => _EditChatGroupDialogState();
}
