import 'package:sembast/sembast.dart';
import 'package:shiftly/features/chat/data/chat_models.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_scope.dart';
import 'package:shiftly/features/chat/data/cache/chat_message_codec.dart';

class ChatMessageCache {
  ChatMessageCache(
    this.storage, {
    this.messageLimit = 500,
    this.conversationLimit = 40,
    this.retention = const Duration(days: 30),
  });
  final ChatCacheDatabase storage;
  final int messageLimit;
  final int conversationLimit;
  final Duration retention;
  Future<void> confirm(ChatCacheScope scope, ChatMessage message) async {
    final page = await read(scope);
    // A standalone sent record cannot establish coverage of a latest page.
    if (page == null) return;
    final values = <String, ChatMessage>{
      for (final item in page.messages) item.id: item,
      message.id: message,
    };
    if (values.length > messageLimit) return;
    final messages = values.values.toList()
      ..sort((a, b) {
        final time = a.createdAt.compareTo(b.createdAt);
        return time == 0 ? a.id.compareTo(b.id) : time;
      });
    await write(
      scope,
      ChatMessagePage(messages: messages, nextCursor: page.nextCursor),
    );
  }

  String _key(ChatCacheScope scope, String? cursor) =>
      'page:${scope.key}:${cursor ?? 'latest'}';
  Future<ChatMessagePage?> read(ChatCacheScope scope, {String? cursor}) async {
    final revision = storage.revision;
    await storage.ready;
    if (!storage.authorized(scope)) return null;
    final record = storage.records.record(_key(scope, cursor));
    final value = await record.get(storage.database);
    if (!storage.authorized(scope) || revision != storage.revision || value == null) return null;
    if ((value['access'] as int) <
        DateTime.now().subtract(retention).millisecondsSinceEpoch) {
      await record.delete(storage.database);
      return null;
    }
    await record.update(storage.database, {
      'access': DateTime.now().millisecondsSinceEpoch,
    });
    final messages = ChatMessageCodec.decode(value['messages']);
    if (messages.any((m) => m.groupId != scope.groupId)) return null;
    return ChatMessagePage(
      messages: messages,
      nextCursor: value['next'] as String?,
    );
  }

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
      await storage.records.record(_key(scope, cursor)).put(transaction, {
        'kind': 'page',
        'scope': scope.key,
        'user': scope.userId,
        'access': DateTime.now().millisecondsSinceEpoch,
        'messages': page.messages.map(ChatMessageCodec.encode).toList(),
        'next': page.nextCursor,
      });
      final rows = await storage.records.find(
        transaction,
        finder: Finder(
          filter: Filter.equals('kind', 'page'),
          sortOrders: [SortOrder('access', false)],
        ),
      );
      final counts = <String, int>{};
      final conversations = <String>{};
      final oldest = DateTime.now().subtract(retention).millisecondsSinceEpoch;
      for (final row in rows) {
        final key = row.value['scope'] as String;
        conversations.add(key);
        counts[key] =
            (counts[key] ?? 0) + (row.value['messages'] as List).length;
        if (conversations.length > conversationLimit ||
            counts[key]! > messageLimit ||
            (row.value['access'] as int) < oldest) {
          await storage.records.record(row.key).delete(transaction);
        }
      }
    });
  }
}
