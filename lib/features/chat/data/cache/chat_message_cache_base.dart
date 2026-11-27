import 'package:sembast/sembast.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_message_store.dart';

abstract class ChatMessageCacheBase implements ChatMessageStore {
  ChatMessageCacheBase(
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

  String pageKey(ChatCacheScope scope, String? cursor) =>
      'page:${scope.key}:${cursor ?? 'latest'}';

  List<ChatMessage> mergeMessages(
    List<ChatMessage> current,
    List<ChatMessage> incoming,
  ) {
    final values = <String, ChatMessage>{};
    for (final message in [...current, ...incoming]) {
      if ((values[message.id]?.revision ?? -1) <= message.revision) {
        values[message.id] = message;
      }
    }
    return values.values.toList()..sort((a, b) {
      final time = a.createdAt.compareTo(b.createdAt);
      return time == 0 ? a.id.compareTo(b.id) : time;
    });
  }

  Future<void> evictOverflowPages(DatabaseClient transaction) async {
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
      counts[key] = (counts[key] ?? 0) + (row.value['messages'] as List).length;
      if (conversations.length > conversationLimit ||
          counts[key]! > messageLimit ||
          (row.value['access'] as int) < oldest) {
        await storage.records.record(row.key).delete(transaction);
      }
    }
  }
}
