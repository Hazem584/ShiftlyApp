import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';

import '../cubit/chat_groups_cubit.dart';
import '../widgets/chat_groups_list.dart';
import '../widgets/chat_message_state.dart';

class ChatGroupsBody extends StatelessWidget {
  const ChatGroupsBody({
    required this.state,
    required this.archived,
    required this.onArchiveSelected,
    super.key,
  });

  final ChatGroupsState state;
  final bool archived;
  final ValueChanged<bool> onArchiveSelected;

  @override
  Widget build(BuildContext context) {
    if (state.loading && state.groups.isEmpty) return const AppContentLoading();
    if (state.groups.isEmpty && state.failure != null) {
      return ChatMessageState(
        message: state.failure!.message,
        action: () => context.read<ChatGroupsCubit>().load(),
      );
    }
    final groups = state.groups
        .where((group) => group.isArchived == archived)
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(context.tr('Active')),
              ),
              ButtonSegment(
                value: true,
                icon: const Icon(Icons.archive_outlined),
                label: Text(context.tr('Archived')),
              ),
            ],
            selected: {archived},
            onSelectionChanged: (selection) =>
                onArchiveSelected(selection.single),
          ),
        ),
        if (state.failure != null)
          MaterialBanner(
            content: Text(context.tr(state.failure!.message)),
            actions: [
              TextButton(
                onPressed: () =>
                    context.read<ChatGroupsCubit>().load(refresh: true),
                child: Text(context.tr('Retry')),
              ),
            ],
          ),
        Expanded(
          child: groups.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ChatMessageState(
                    message: archived
                        ? 'No archived chats.'
                        : 'No active chats.',
                  ),
                )
              : ChatGroupsList(groups: groups),
        ),
      ],
    );
  }
}
