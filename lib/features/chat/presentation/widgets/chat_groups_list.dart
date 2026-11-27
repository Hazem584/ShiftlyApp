import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/routing/app_routes.dart';
import 'package:shiftly/features/chat/domain/entities/chat_group.dart';

import '../cubit/chat_groups_cubit.dart';
import '../screens/chat_screen.dart';
import 'chat_group_tile.dart';

class ChatGroupsList extends StatelessWidget {
  const ChatGroupsList({required this.groups, super.key});

  final List<ChatGroup> groups;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChatGroupsCubit>();
    return RefreshIndicator(
      onRefresh: () => cubit.load(refresh: true),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 360;
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              narrow ? 8 : 16,
              8,
              narrow ? 8 : 16,
              96,
            ),
            itemCount: groups.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => ChatGroupTile(
              group: groups[index],
              narrow: narrow,
              onTap: () => _openGroup(context, cubit, groups[index].id),
            ),
          );
        },
      ),
    );
  }

  void _openGroup(BuildContext context, ChatGroupsCubit cubit, String groupId) {
    if (cubit.scope?.isManager == true) {
      context.push(AppRoutes.chatGroup(groupId));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ChatScreen(groupId: groupId)),
    );
  }
}
