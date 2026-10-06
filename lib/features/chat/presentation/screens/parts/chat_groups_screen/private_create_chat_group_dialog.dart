part of '../../chat_groups_screen.dart';

class _CreateChatGroupDialog extends StatefulWidget {
  const _CreateChatGroupDialog({
    required this.cubit,
    required this.scope,
    required this.employees,
  });

  final ChatGroupsCubit cubit;
  final FeatureSessionScope scope;
  final List<Employee> employees;

  @override
  State<_CreateChatGroupDialog> createState() => _CreateChatGroupDialogState();
}
