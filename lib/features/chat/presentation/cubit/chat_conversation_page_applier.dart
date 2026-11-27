import 'dart:async';

import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_pager.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_state.dart';

void applyLoadedChatConversationPage(
  ChatConversationPager pager,
  FeatureSessionScope scope,
  String groupId,
  ChatMessagePage page,
) {
  final host = pager.host;
  host.validateMessages(page.messages, scope, groupId);
  final currentMessages = host.state.messages;
  final overlaps = currentMessages.isEmpty ||
      page.messages.isEmpty ||
      page.messages.any((m) => currentMessages.any((old) => old.id == m.id));
  final merged = host.mergeMessages(page.messages, currentMessages);
  if (!overlaps && !host.state.historyGap) {
    pager.historyCursor = host.state.nextCursor;
    pager.gapBoundaryIds = currentMessages.map((m) => m.id).toSet();
  }
  final cursor = !overlaps
      ? page.nextCursor
      : currentMessages.isNotEmpty && pager.latestLoaded
      ? host.state.nextCursor
      : page.nextCursor;
  host.emitState(
    ChatConversationState(
      loading: false,
      messages: merged,
      nextCursor: cursor,
      pending: host.confirmPending(merged),
      historyGap: host.state.historyGap || !overlaps,
    ),
  );
  pager.latestLoaded = true;
  final cacheRevision = host.messageCache?.storage.revision;
  pager.pagePersistence = pager.pagePersistence.then((_) async {
    if (cacheRevision != host.messageCache?.storage.revision) return;
    try {
      await host.messageCache?.write(
        ChatCacheScope.fromSession(scope, groupId),
        page,
      );
    } catch (_) {}
  });
  host.markNewestRead(merged);
  unawaited(pager.drainOutbox());
}
