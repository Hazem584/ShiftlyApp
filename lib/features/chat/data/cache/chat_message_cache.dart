import 'package:sembast/sembast.dart';
import 'package:shiftly/features/chat/data/cache/chat_message_cache_base.dart';
import 'package:shiftly/features/chat/data/cache/chat_message_cache_write.dart';
import 'package:shiftly/features/chat/data/cache/chat_message_codec.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

class ChatMessageCache extends ChatMessageCacheBase with ChatMessageCacheWrite {
  ChatMessageCache(
    super.storage, {
    super.messageLimit,
    super.conversationLimit,
    super.retention,
  });

  @override
  Future<ChatMessagePage?> read(ChatCacheScope scope, {String? cursor}) async {
    final revision = storage.revision;
    await storage.ready;
    if (!storage.authorized(scope)) return null;
    final record = storage.records.record(pageKey(scope, cursor));
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
}
