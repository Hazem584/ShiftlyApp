import 'dart:io';
import 'dart:typed_data';

import 'package:sembast/sembast.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_outbox_operation.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_outbox_store.dart';
import 'package:shiftly/features/chat/domain/services/chat_outbox_coordinator.dart';
import 'package:uuid/uuid.dart';

class ChatOutboxStorage implements ChatOutboxStore {
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
  Future<String> ownMedia(ChatCacheScope scope, Uint8List bytes) async {
    await storage.ready;
    if (!storage.writable(scope)) throw StateError('Chat access unavailable');
    final name = '${const Uuid().v4()}.bin';
    final temporary = File(
      '${storage.directory.path}/${const Uuid().v4()}.part',
    );
    final target = File('${storage.directory.path}/$name');
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      if (!storage.writable(scope)) throw StateError('Chat access unavailable');
      await temporary.rename(target.path);
      return name;
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  @override
  Future<void> save(ChatCacheScope scope, ChatOutboxOperation operation) async {
    await storage.ready;
    if (!storage.writable(scope)) throw StateError('Chat access unavailable');
    await storage.database.transaction((transaction) async {
      if (!storage.writable(scope)) throw StateError('Chat access unavailable');
      final count = await storage.records.count(
        transaction,
        filter: Filter.equals('kind', 'outbox'),
      );
      final record = storage.records.record(
        'outbox:${scope.key}:${operation.id}',
      );
      if (count >= operationLimit && await record.get(transaction) == null) {
        throw StateError('Outbox is full');
      }
      await record.put(transaction, {
        ...operation.toJson(),
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
    final rows = await storage.records.find(
      storage.database,
      finder: Finder(
        filter: Filter.and([
          Filter.equals('kind', 'outbox'),
          Filter.equals('scope', scope.key),
        ]),
        sortOrders: [SortOrder('created'), SortOrder('id')],
      ),
    );
    if (!storage.authorized(scope)) return [];
    return rows.map((row) => ChatOutboxOperation.fromJson(row.value)).toList();
  }

  @override
  File mediaFile(String name) {
    if (!RegExp(r'^[a-f0-9-]+\.bin$').hasMatch(name)) {
      throw const FormatException('Invalid media');
    }
    return File('${storage.directory.path}/$name');
  }

  @override
  Future<void> remove(
    ChatCacheScope scope,
    ChatOutboxOperation operation,
  ) async {
    await storage.records
        .record('outbox:${scope.key}:${operation.id}')
        .delete(storage.database);
    if (operation.file case final name?) {
      final file = mediaFile(name);
      await storage.deleteFile(file);
    }
  }
}
