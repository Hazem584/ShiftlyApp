import 'dart:async';

import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_pager.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_message_merger.dart';

Future<void> loadOlderChatMessages(ChatConversationPager pager) async {
  final host = pager.host;
  final scope = host.scope, groupId = host.groupId, previous = host.state;
  final expectedGeneration = host.generation;
  await pager.pagePersistence;
  if (host.generation != expectedGeneration ||
      scope == null ||
      groupId == null ||
      previous.loadingOlder ||
      pager.loadingPage ||
      !previous.hasMore) {
    return;
  }
  final generation = host.generation, request = ++pager.request;
  pager.loadingPage = true;
  host.emitState(previous.copyWith(loadingOlder: true, clearFailure: true));
  try {
    final cacheScope = ChatCacheScope.fromSession(scope, groupId);
    final cached = await host.messageCache?.read(
      cacheScope,
      cursor: previous.nextCursor,
    );
    final page = cached ??
        await host.repository.listMessages(
          scope.workspaceId,
          groupId,
          cursor: previous.nextCursor,
        );
    if (!pager.current(scope, groupId, generation, request)) return;
    host.validateMessages(page.messages, scope, groupId);
    try {
      await host.messageCache?.write(cacheScope, page, cursor: previous.nextCursor);
    } catch (_) {}
    if (!pager.current(scope, groupId, generation, request)) return;
    final merged = host.mergeMessages(page.messages, host.state.messages);
    final gapClosed = host.state.historyGap &&
        (page.messages.any((m) => pager.gapBoundaryIds.contains(m.id)) ||
            page.nextCursor == null);
    final cursor = gapClosed ? pager.historyCursor : page.nextCursor;
    if (gapClosed) pager.gapBoundaryIds.clear();
    host.emitState(
      host.state.copyWith(
        messages: merged,
        nextCursor: cursor,
        clearCursor: cursor == null,
        historyGap: host.state.historyGap && !gapClosed,
        loadingOlder: false,
        pending: host.confirmPending(merged),
      ),
    );
  } catch (error) {
    if (!pager.current(scope, groupId, generation, request)) return;
    if (isChatAccessLost(error)) return await host.loseAccess();
    host.emitState(
      host.state.copyWith(
        loadingOlder: false,
        failure: chatConversationFailure(error, 'Unable to load older messages.'),
      ),
    );
  } finally {
    pager.finishPageLoad(scope, groupId, generation);
  }
}
