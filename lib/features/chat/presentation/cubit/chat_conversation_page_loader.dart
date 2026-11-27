import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cache_loader.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_page_applier.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_pager.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_state.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_message_merger.dart';

Future<void> loadChatConversationPage(
  ChatConversationPager pager, {
  bool refresh = false,
}) async {
  final host = pager.host, scope = host.scope, groupId = host.groupId;
  if (scope == null || groupId == null) return;
  if (pager.loadingPage) {
    if (refresh) pager.refreshQueued = true;
    return;
  }
  pager.loadingPage = true;
  final gen = host.generation, req = ++pager.request, prev = host.state;
  if (refresh && prev.messages.isNotEmpty) {
    host.emitState(prev.copyWith(refreshing: true, clearFailure: true));
  }
  try {
    final restored = await restoreChatConversationCache(
      pager,
      scope,
      groupId,
      gen,
      req,
    );
    if (!restored) return;
    final page = await host.repository.listMessages(scope.workspaceId, groupId);
    if (!pager.current(scope, groupId, gen, req)) return;
    applyLoadedChatConversationPage(pager, scope, groupId, page);
  } catch (error) {
    if (!pager.current(scope, groupId, gen, req)) return;
    pager.clearInboxHint();
    if (isChatAccessLost(error)) return await host.loseAccess();
    final failure = chatConversationFailure(error, 'Unable to load messages.');
    host.emitState(
      host.state.messages.isEmpty
          ? ChatConversationState(
              loading: false,
              failure: failure,
              pending: host.state.pending,
            )
          : host.state.copyWith(
              refreshing: false,
              failure: failure,
              pending: host.state.pending,
            ),
    );
  } finally {
    pager.finishPageLoad(scope, groupId, gen);
  }
}
