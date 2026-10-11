import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/chat/presentation/dialogs/chat_search_dialog.dart';

abstract final class ChatConversationTools {
  static Future<ChatMessage?> search(
    BuildContext context,
    String groupId,
    bool pinned,
  ) async {
    final scope = context.read<ChatGroupsCubit>().scope;
    if (scope == null) return null;
    return showDialog<ChatMessage>(
      context: context,
      builder: (_) => ChatSearchDialog(
        repository: context.read<ChatRepository>(),
        workspaceId: scope.workspaceId,
        groupId: groupId,
        timezone: scope.timezone,
        pinned: pinned,
      ),
    );
  }

  static Future<void> pin(
    BuildContext context,
    String groupId,
    ChatMessage message,
  ) async {
    final scope = context.read<ChatGroupsCubit>().scope;
    if (scope == null) return;
    try {
      final canonical = await context.read<ChatRepository>().pinMessage(
        scope.workspaceId,
        groupId,
        message.id,
        pinned: message.pinnedAt == null,
      );
      if (context.mounted) {
        context.read<ChatConversationCubit>().applyMessageUpdate(canonical);
        await context.read<ChatConversationCubit>().load(refresh: true);
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr(ApiErrorParser.parse(error).message)),
          ),
        );
      }
    }
  }
}
