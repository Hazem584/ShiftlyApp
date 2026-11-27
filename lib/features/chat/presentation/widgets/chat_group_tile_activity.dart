import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';

class ChatGroupTileActivity extends StatelessWidget {
  const ChatGroupTileActivity({required this.group, super.key});
  final ChatGroup group;

  @override
  Widget build(BuildContext context) => Column(
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
            group.unreadCount > 99
                ? '99+'
                : context.tr('{value1}', {
                    'value1': (group.unreadCount).toString(),
                  }),
          ),
        ),
    ],
  );
}
