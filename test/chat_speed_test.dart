import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database.dart';
import 'package:shiftly/features/chat/data/cache/chat_message_cache.dart';
import 'package:shiftly/features/chat/data/mock_chat_repository.dart';
import 'package:shiftly/features/chat/data/outbox/chat_outbox_storage.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_group_details_cubit.dart';

import 'chat_cache_outbox_test.dart' as f;

ChatGroup summary() => ChatGroup(
  id: f.group,
  workspaceId: f.workspace,
  name: 'Fixture',
  memberCount: 1,
  unreadCount: 0,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ChatCacheDatabase storage;
  late ChatOutboxStorage outbox;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('shiftly-speed-');
    storage = ChatCacheDatabase(
      await databaseFactoryMemory.openDatabase(directory.path),
      directory,
    );
    storage.bindSession(f.session);
    await storage.ready;
    storage.grant(f.scope);
    outbox = ChatOutboxStorage(storage);
  });
  tearDown(() async {
    await storage.close();
    await directory.delete(recursive: true);
  });

  test('fresh messages render before a blocked cache write', () async {
    final cache = f.GatedMessageCache(storage)..blockNextWrite = true;
    final repository = f.FixtureRepository()
      ..page = ChatMessagePage(messages: [f.message(1)]);
    final cubit = ChatConversationCubit(
      repository,
      const NoopChatRealtime(),
      messageCache: cache,
      outbox: outbox,
    )..bind(f.session, f.group);
    await cache.writeStarted.future;
    expect(cubit.state.loading, isFalse);
    expect(cubit.state.messages.single.id, f.message(1).id);
    expect(cache.releaseWrite.isCompleted, isFalse);
    cache.releaseWrite.complete();
    await cubit.close();
  });

  test('a slow upload cannot block text in the same conversation', () async {
    final repository = _SlowUpload();
    final cubit = ChatConversationCubit(
      repository,
      const NoopChatRealtime(),
      messageCache: ChatMessageCache(storage),
      outbox: outbox,
    )..bind(f.session, f.group);
    await f.until(() => !cubit.state.loading);
    expect(await cubit.sendImage(f.jpeg), isNotNull);
    await repository.uploadStarted.future;
    expect(await cubit.send('Text during upload'), isTrue);
    await f.until(() => cubit.state.messages.any((m) => m.type == 'TEXT'));
    expect(repository.releaseUpload.isCompleted, isFalse);
    expect(cubit.state.pending.single.mediaType, PendingChatMediaType.image);
    repository.releaseUpload.complete();
    await f.until(() => cubit.state.pending.isEmpty);
    await _cleaned(outbox);
    await cubit.close();
  });

  test(
    'server confirmation renders before local confirmation persistence',
    () async {
      final cache = _SlowConfirmation(storage);
      final cubit = ChatConversationCubit(
        f.FixtureRepository(),
        const NoopChatRealtime(),
        messageCache: cache,
        outbox: outbox,
      )..bind(f.session, f.group);
      await f.until(() => !cubit.state.loading);
      expect(await cubit.send('Immediate confirmation'), isTrue);
      await cache.started.future;
      expect(cubit.state.messages, hasLength(1));
      expect(cubit.state.pending, isEmpty);
      expect(cache.release.isCompleted, isFalse);
      cache.release.complete();
      await _cleaned(outbox);
      await cubit.close();
    },
  );

  test(
    'authorized summary enables composer data before details refresh',
    () async {
      final gate = Completer<ChatGroup>();
      final cubit = ChatGroupDetailsCubit(
        f.FixtureRepository(),
        cacheDatabase: storage,
        loadGroup: () => gate.future,
      )..bind(f.session, f.group, initialGroup: summary());
      expect(cubit.state.group?.name, 'Fixture');
      expect(cubit.state.loading, isFalse);
      gate.complete(summary());
      await cubit.close();
    },
  );

  test(
    'persisted summary alone cannot grant access after session restart',
    () async {
      await storage.revoke(f.scope);
      final gate = Completer<ChatGroup>();
      final cubit = ChatGroupDetailsCubit(
        f.FixtureRepository(),
        cacheDatabase: storage,
        loadGroup: () => gate.future,
      )..bind(f.session, f.group, initialGroup: summary());
      expect(cubit.state.group, isNull);
      expect(cubit.state.loading, isTrue);
      gate.complete(summary());
      await cubit.close();
    },
  );
}

Future<void> _cleaned(ChatOutboxStorage outbox) async {
  for (var i = 0; i < 300; i++) {
    if ((await outbox.restore(f.scope)).isEmpty) return;
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
  fail('Outbox cleanup timed out');
}

class _SlowConfirmation extends ChatMessageCache {
  _SlowConfirmation(super.storage);
  final started = Completer<void>(), release = Completer<void>();
  @override
  Future<void> confirm(scope, ChatMessage message) async {
    if (!started.isCompleted) started.complete();
    await release.future;
    await super.confirm(scope, message);
  }
}

class _SlowUpload extends f.FixtureRepository {
  final uploadStarted = Completer<void>(), releaseUpload = Completer<void>();
  @override
  Future<ChatUploadAuthorization> initiateUpload(
    String w,
    String g, {
    required String type,
    required String mimeType,
    required int sizeBytes,
    int? durationMs,
    String? fileName,
  }) async => ChatUploadAuthorization.fromJson({
    'uploadId': '77777777-7777-4777-8777-777777777777',
    'bucket': 'chat-media',
    'path': 'fixture.jpg',
    'uploadToken': 'fixture',
    'signedUploadUrl': 'https://fixture.invalid/upload',
    'expiresAt': DateTime.now()
        .toUtc()
        .add(const Duration(hours: 1))
        .toIso8601String(),
  });
  @override
  Future<void> uploadSigned(
    ChatUploadAuthorization authorization,
    Uint8List bytes,
    String mimeType, {
    void Function(int sent, int total)? onProgress,
    ChatUploadCancellation? cancellation,
  }) async {
    uploadStarted.complete();
    await releaseUpload.future;
  }
}
