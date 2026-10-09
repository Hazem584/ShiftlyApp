import 'package:sembast/sembast.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database.dart';
import 'package:shiftly/features/chat/data/cache/chat_message_codec.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_message_store.dart';

class ChatMessageCache implements ChatMessageStore {
  ChatMessageCache(
    this.storage, {
    this.messageLimit = 500,
    this.conversationLimit = 40,
    this.retention = const Duration(days: 30),
  });
  @override
  final ChatCacheDatabase storage;
  final int messageLimit;
  final int conversationLimit;
  final Duration retention;
  @override
  Future<void> confirm(ChatCacheScope scope, ChatMessage message) async {
    final revision = storage.revision;
    await storage.ready;
    if (!storage.authorized(scope)) return;
    await storage.database.transaction((transaction) async {
      if (!storage.authorized(scope) || revision != storage.revision) return;
      final record = storage.records.record(_key(scope, null));
      final page = await record.get(transaction);
      if (!storage.authorized(scope) || revision != storage.revision) return;
      // A standalone sent record cannot establish coverage of a latest page.
      if (page == null ||
          (page['access'] as int) <
              DateTime.now().subtract(retention).millisecondsSinceEpoch) {
        return;
      }
      final messages = _merge(ChatMessageCodec.decode(page['messages']), [
        message,
      ]);
      if (messages.length > messageLimit) return;
      // Keep local confirmations with the page until eviction. A refresh can
      // have captured its server snapshot before these sends were committed.
      final confirmed = _merge(
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

  List<ChatMessage> _merge(
    List<ChatMessage> current,
    List<ChatMessage> incoming,
  ) {
    final values = <String, ChatMessage>{
      for (final message in current) message.id: message,
      for (final message in incoming) message.id: message,
    };
    return values.values.toList()..sort((a, b) {
      final time = a.createdAt.compareTo(b.createdAt);
      return time == 0 ? a.id.compareTo(b.id) : time;
    });
  }

  String _key(ChatCacheScope scope, String? cursor) =>
      'page:${scope.key}:${cursor ?? 'latest'}';
  @override
  Future<ChatMessagePage?> read(ChatCacheScope scope, {String? cursor}) async {
    final revision = storage.revision;
    await storage.ready;
    if (!storage.authorized(scope)) return null;
    final record = storage.records.record(_key(scope, cursor));
    final value = await record.get(storage.database);
    if (!storage.authorized(scope) ||
        revision != storage.revision ||
        value == null) {
      return null;
    }
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
      final record = storage.records.record(_key(scope, cursor));
      final previous = cursor == null ? await record.get(transaction) : null;
      if (!storage.authorized(scope) || revision != storage.revision) return;
      final confirmed =
          previous != null &&
              (previous['access'] as int) >=
                  DateTime.now().subtract(retention).millisecondsSinceEpoch
          ? ChatMessageCodec.decode(previous['confirmed'] ?? const [])
          : <ChatMessage>[];
      final messages = _merge(confirmed, page.messages);
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
