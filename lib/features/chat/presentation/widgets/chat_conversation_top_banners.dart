import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_group_details_cubit.dart';

List<Widget> buildChatConversationTopBanners(
  BuildContext context,
  ChatGroupDetailsState details,
) => [
  if (details.failure != null)
    MaterialBanner(
      content: Text(context.tr(details.failure!.message)),
      actions: [
        TextButton(
          onPressed: context.read<ChatGroupDetailsCubit>().load,
          child: Text(context.tr('Retry')),
        ),
      ],
    ),
  if (details.group?.isArchived == true)
    ColoredBox(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            const Icon(Icons.archive_outlined, size: 18),
            Text(context.tr('Archived group — read only')),
          ],
        ),
      ),
    ),
];

List<Widget> buildChatMessageSectionBanners(
  BuildContext context,
  ChatConversationState state,
  ChatConversationCubit cubit,
) => [
  if (state.historyGap)
    TextButton(
      onPressed: state.loadingOlder ? null : cubit.loadOlder,
      child: Text(context.tr('History has a gap — load missing messages')),
    ),
  if (state.failure != null && state.messages.isNotEmpty)
    TextButton(
      onPressed: () => cubit.load(refresh: true),
      child: Text(context.tr('Refresh unavailable — retry')),
    ),
];
