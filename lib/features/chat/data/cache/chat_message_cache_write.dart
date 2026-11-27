import 'package:sembast/sembast.dart';
import 'package:shiftly/features/chat/data/cache/chat_message_cache_base.dart';
import 'package:shiftly/features/chat/data/cache/chat_message_codec.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

mixin ChatMessageCacheWrite on ChatMessageCacheBase {
  @override
  Future<void> confirm(ChatCacheScope scope, ChatMessage message) async {
    final revision = storage.revision;
    await storage.ready;
    if (!storage.authorized(scope)) return;
    await storage.database.transaction((transaction) async {
      if (!storage.authorized(scope) || revision != storage.revision) return;
      final record = storage.records.record(pageKey(scope, null));
      final page = await record.get(transaction);
      if (!storage.authorized(scope) || revision != storage.revision) return;
      final cutoff = DateTime.now().subtract(retention).millisecondsSinceEpoch;
      if (page == null || (page['access'] as int) < cutoff) return;
      final messages = mergeMessages(
        ChatMessageCodec.decode(page['messages']),
        [message],
      );
      if (messages.length > messageLimit) return;
      final confirmed = mergeMessages(
        ChatMessageCodec.decode(page['confirmed'] ?? const []),
        [message],
      );
      await record.update(transaction, {
        'access': DateTime.now().millisecondsSinceEpoch,
        'messages': messages.map(ChatMessageCodec.encode).toList(),
        'confirmed': confirmed.map(ChatMessageCodec.encode).toList(),
      });
    });
  }

  @override
  Future<void> write(
    ChatCacheScope scope,
    ChatMessagePage page, {
    String? cursor,
  }) async {
    final revision = storage.revision;
    await storage.ready;
    if (!storage.authorized(scope)) return;
    await storage.database.transaction((transaction) async {
      if (!storage.authorized(scope) || revision != storage.revision) return;
      final record = storage.records.record(pageKey(scope, cursor));
      final previous = cursor == null ? await record.get(transaction) : null;
      if (!storage.authorized(scope) || revision != storage.revision) return;
      final cutoff = DateTime.now().subtract(retention).millisecondsSinceEpoch;
      final confirmed =
          previous != null && (previous['access'] as int) >= cutoff
          ? ChatMessageCodec.decode(previous['confirmed'] ?? const [])
          : <ChatMessage>[];
      final messages = mergeMessages(confirmed, page.messages);
      await record.put(transaction, {
        'kind': 'page',
        'scope': scope.key,
        'user': scope.userId,
        'access': DateTime.now().millisecondsSinceEpoch,
        'messages': messages.map(ChatMessageCodec.encode).toList(),
        if (cursor == null)
          'confirmed': confirmed.map(ChatMessageCodec.encode).toList(),
        'next': page.nextCursor,
      });
      await evictOverflowPages(transaction);
    });
  }
}
