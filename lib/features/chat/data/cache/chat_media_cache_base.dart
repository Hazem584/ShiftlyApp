import 'dart:async';

import 'package:dio/dio.dart';
import 'package:shiftly/core/storage/platform_file.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_media_store.dart';

abstract class ChatMediaCacheBase implements ChatMediaStore {
  ChatMediaCacheBase(
    this.storage, {
    Dio? downloadClient,
    this.byteLimit = 128 * 1024 * 1024,
    this.retention = const Duration(days: 14),
    this.maxTransfers = 2,
  }) : downloadClient =
           downloadClient ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 20),
               receiveTimeout: const Duration(seconds: 45),
             ),
           ) {
    storage.listeners.add(invalidateActiveTransfers);
  }

  @override
  final ChatCacheDatabase storage;
  final Dio downloadClient;
  final int byteLimit;
  final Duration retention;
  final int maxTransfers;
  final Map<String, Future<ChatLocalFile>> inFlight = {};
  final Map<String, CancelToken> tokens = {};
  final Map<String, ChatCacheScope> scopes = {};
  final List<Completer<void>> waiting = [];
  int activeTransfers = 0;
  Future<void> inspections = Future<void>.value();

  String mediaKey(ChatCacheScope scope, ChatMessage message) =>
      'media:${scope.key}:${message.id}:${message.attachment?.id}';
  @override
  void pin(ChatLocalFile file) => storage.pin(file);
  @override
  void unpin(ChatLocalFile file) => storage.unpin(file);

  Future<void> acquireTransferSlot() async {
    if (activeTransfers < maxTransfers) {
      activeTransfers++;
      return;
    }
    final waiter = Completer<void>();
    waiting.add(waiter);
    await waiter.future;
  }

  void releaseTransferSlot() => waiting.isNotEmpty
      ? waiting.removeAt(0).complete()
      : activeTransfers--;

  void invalidateActiveTransfers() {
    for (final e in tokens.entries) {
      if (!storage.authorized(scopes[e.key]!)) e.value.cancel();
    }
  }

  void close() {
    storage.listeners.remove(invalidateActiveTransfers);
    for (final token in tokens.values) {
      token.cancel();
    }
    downloadClient.close(force: true);
  }
}
