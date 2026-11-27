import 'package:sembast/sembast.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database.dart';
import 'package:shiftly/features/chat/data/outbox/chat_outbox_media_storage.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_outbox_operation.dart';
import 'package:shiftly/features/chat/domain/services/chat_outbox_coordinator.dart';

class ChatOutboxStorage extends ChatOutboxMediaStorage {
  ChatOutboxStorage(
    this.storage, {
    this.operationLimit = 100,
    ChatOutboxCoordinator? coordinator,
  }) : coordinator = coordinator ?? ChatOutboxCoordinator();

  @override
  final ChatOutboxCoordinator coordinator;
  @override
  final ChatCacheDatabase storage;
  final int operationLimit;

  @override
  Future<void> save(ChatCacheScope scope, ChatOutboxOperation op) async {
    await storage.ready;
    if (!storage.writable(scope)) throw StateError('Chat access unavailable');
    await storage.database.transaction((tx) async {
      if (!storage.writable(scope)) throw StateError('Chat access unavailable');
      final filter = Filter.equals('kind', 'outbox');
      final count = await storage.records.count(tx, filter: filter);
      final rec = storage.records.record('outbox:${scope.key}:${op.id}');
      if (count >= operationLimit && await rec.get(tx) == null) {
        throw StateError('Outbox is full');
      }
      await rec.put(tx, {
        ...op.toJson(),
        'kind': 'outbox',
        'scope': scope.key,
        'user': scope.userId,
      });
    });
  }

  @override
  Future<List<ChatOutboxOperation>> restore(ChatCacheScope scope) async {
    await storage.ready;
    if (!storage.authorized(scope)) return [];
    final filter = Filter.and([
      Filter.equals('kind', 'outbox'),
      Filter.equals('scope', scope.key),
    ]);
    final rows = await storage.records.find(
      storage.database,
      finder: Finder(
        filter: filter,
        sortOrders: [SortOrder('created'), SortOrder('id')],
      ),
    );
    if (!storage.authorized(scope)) return [];
    return rows.map((row) => ChatOutboxOperation.fromJson(row.value)).toList();
  }

  @override
  Future<void> remove(ChatCacheScope scope, ChatOutboxOperation op) async {
    final rec = storage.records.record('outbox:${scope.key}:${op.id}');
    await rec.delete(storage.database);
    if (op.file case final name?) await storage.deleteFile(mediaFile(name));
  }
}
