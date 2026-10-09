import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_cache.dart';
import 'package:shiftly/features/chat/data/cache/chat_message_cache.dart';
import 'package:shiftly/features/chat/data/mock_chat_repository.dart';
import 'package:shiftly/features/chat/data/outbox/chat_outbox_storage.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/entities/chat_outbox_operation.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/widgets/pending_media_bubble.dart';

const user = '11111111-1111-4111-8111-111111111111';
const workspace = '22222222-2222-4222-8222-222222222222';
const group = '33333333-3333-4333-8333-333333333333';
const membership = '44444444-4444-4444-8444-444444444444';
const session = FeatureSessionScope(
  userId: user,
  workspaceId: workspace,
  membershipId: membership,
  timezone: 'Etc/UTC',
  role: WorkspaceRole.employee,
);
const scope = ChatCacheScope(user, workspace, group);
final jpeg = Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]);

ChatMessage message(
  int index, {
  String type = 'TEXT',
  String? clientId,
}) => ChatMessage(
  id: '55555555-5555-4555-8555-${index.toString().padLeft(12, '0')}',
  groupId: group,
  type: type,
  text: type == 'TEXT' ? 'fixture' : null,
  location: type == 'LOCATION'
      ? const ChatLocation(latitude: 0, longitude: 0)
      : null,
  clientMessageId: clientId,
  sender: const ChatSender(
    membershipId: membership,
    fullName: 'Fixture sender',
  ),
  createdAt: DateTime.utc(2026, 10, 1, 10, index),
  attachment: type == 'IMAGE' || type == 'VOICE'
      ? ChatAttachment(
          id: '66666666-6666-4666-8666-${index.toString().padLeft(12, '0')}',
          category: type,
          mimeType: type == 'IMAGE' ? 'image/jpeg' : 'audio/ogg',
          sizeBytes: 4,
          durationMs: type == 'VOICE' ? 1000 : null,
        )
      : null,
);

Future<void> until(bool Function() condition) async {
  for (var i = 0; i < 300; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
  throw StateError('Fixture condition timed out');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ChatCacheDatabase storage;
  late ChatMessageCache cache;
  late ChatOutboxStorage outbox;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('shiftly-chat-fixture-');
    storage = ChatCacheDatabase(
      await databaseFactoryMemory.openDatabase(directory.path),
      directory,
    );
    storage.bindSession(session);
    await storage.ready;
    storage.grant(scope);
    cache = ChatMessageCache(storage);
    outbox = ChatOutboxStorage(storage);
  });
  tearDown(() async {
    await storage.ready;
    await storage.close();
    await directory.delete(recursive: true);
  });

  test('cached reopen renders before delayed refresh and retains content on failure', () async {
    await cache.write(
      scope,
      ChatMessagePage(messages: [message(1)], nextCursor: 'older'),
    );
    final gate = Completer<ChatMessagePage>();
    final repository = FixtureRepository()..nextPage = gate.future;
    final cubit = ChatConversationCubit(
      repository,
      const NoopChatRealtime(),
      messageCache: cache,
      outbox: outbox,
    )..bind(session, group);
    await until(() => !cubit.state.loading && cubit.state.messages.isNotEmpty);
    expect(gate.isCompleted, isFalse);
    expect(cubit.state.nextCursor, 'older');
    await until(() => repository.listCalls > 0);
    gate.completeError(const ApiException(message: 'Fixture offline'));
    await until(() => cubit.state.failure != null);
    expect(cubit.state.messages.single.id, message(1).id);
    expect(cubit.state.refreshing, isFalse);
    await cubit.close();
  });

  test('older pages are reused, latest refresh preserves oldest cursor and deduplicates', () async {
    final repository = FixtureRepository()
      ..page = ChatMessagePage(
        messages: [message(3), message(2)],
        nextCursor: 'older',
      )
      ..olderPage = ChatMessagePage(
        messages: [message(1)],
        nextCursor: 'oldest',
      );
    var cubit = ChatConversationCubit(
      repository,
      const NoopChatRealtime(),
      messageCache: cache,
      outbox: outbox,
    )..bind(session, group);
    await until(() => !cubit.state.loading);
    await cubit.loadOlder();
    repository.page = ChatMessagePage(
      messages: [message(4), message(3)],
      nextCursor: 'new-boundary',
    );
    await cubit.load(refresh: true);
    expect(
      cubit.state.messages.map((m) => m.id),
      [1, 2, 3, 4].map((i) => message(i).id),
    );
    expect(cubit.state.nextCursor, 'oldest');
    await cubit.close();
    repository.page = ChatMessagePage(
      messages: [message(3), message(2)],
      nextCursor: 'older',
    );
    cubit = ChatConversationCubit(
      repository,
      const NoopChatRealtime(),
      messageCache: cache,
      outbox: outbox,
    )..bind(session, group);
    await until(() => !cubit.state.refreshing && !cubit.state.loading);
    // Latest boundary can differ from the cached one; disjoint ranges are explicit, never treated as complete.
    await cubit.close();
    expect(await cache.read(scope, cursor: 'older'), isNotNull);
    expect(repository.olderCalls, 1);
  });

  test(
    'disjoint latest refresh retains valid history and announces a gap',
    () async {
      final repository = FixtureRepository()
        ..page = ChatMessagePage(messages: [message(1)], nextCursor: 'oldest');
      final cubit = ChatConversationCubit(repository, const NoopChatRealtime())
        ..bind(session, group);
      await until(() => !cubit.state.loading);
      repository.page = ChatMessagePage(
        messages: [message(5)],
        nextCursor: 'missing',
      );
      await cubit.load(refresh: true);
      expect(cubit.state.historyGap, isTrue);
      expect(cubit.state.messages, hasLength(2));
      expect(cubit.state.nextCursor, 'missing');
      repository.olderPage = ChatMessagePage(
        messages: [message(4), message(1)],
        nextCursor: 'unused',
      );
      await cubit.loadOlder();
      expect(cubit.state.historyGap, isFalse);
      expect(cubit.state.nextCursor, 'oldest');
      await cubit.close();
    },
  );

  test('rapid text and location accept durably while one earlier request is blocked', () async {
    final gate = Completer<ChatMessage>();
    final repository = FixtureRepository()..sendGate = gate;
    final racingCache = GatedMessageCache(storage);
    final cubit = ChatConversationCubit(
      repository,
      const NoopChatRealtime(),
      messageCache: racingCache,
      outbox: outbox,
    );
    addTearDown(cubit.close);
    final loaded = cubit.stream.firstWhere((state) => !state.loading);
    cubit.bind(session, group);
    await loaded;
    expect(await cubit.send('  fixture one  '), isTrue);
    await repository.firstSendStarted.future;
    expect(await cubit.send('fixture two'), isTrue);
    expect(
      await cubit.sendLocation(const ChatLocation(latitude: 0, longitude: 0)),
      isTrue,
    );
    expect(cubit.state.pending, hasLength(3));
    expect(cubit.state.pending.first.text, 'fixture one');
    final acceptedIds = cubit.state.pending
        .map((p) => p.clientMessageId)
        .toSet();
    expect(acceptedIds, hasLength(3));
    expect(
      (await outbox.restore(scope)).map((operation) => operation.id).toSet(),
      acceptedIds,
    );
    expect(repository.sendIds, hasLength(1));
    final id = repository.sendIds.single;

    // Hold a stale empty refresh at its persistence boundary while all three
    // sends finish. Neither its cache write nor its state emission may lose them.
    racingCache.blockNextWrite = true;
    final refresh = cubit.load(refresh: true);
    await racingCache.writeStarted.future;
    final delivered = cubit.stream.firstWhere((state) => state.pending.isEmpty);
    repository.sendGate = null;
    gate.complete(message(20, clientId: id));
    await delivered;
    expect(repository.sendIds, hasLength(3));
    expect(repository.sendIds.toSet(), acceptedIds);
    void verifyMessages(List<ChatMessage> messages) {
      expect(messages, hasLength(3));
      expect(messages.map((message) => message.id).toSet(), hasLength(3));
      expect(
        messages.map((message) => message.clientMessageId).toSet(),
        acceptedIds,
      );
      expect(messages.map((message) => message.type), [
        'TEXT',
        'TEXT',
        'LOCATION',
      ]);
    }

    verifyMessages(cubit.state.messages);
    verifyMessages((await racingCache.read(scope))!.messages);
    expect(await outbox.restore(scope), isEmpty);

    racingCache.releaseWrite.complete();
    await refresh;
    verifyMessages(cubit.state.messages);
    verifyMessages((await racingCache.read(scope))!.messages);
    // A later server refresh repeats the same confirmations without duplicates.
    repository.page = ChatMessagePage(
      messages: repository.committed.values.toList(),
    );
    await cubit.load(refresh: true);
    verifyMessages(cubit.state.messages);
    verifyMessages((await racingCache.read(scope))!.messages);
  });

  test(
    'outbox full fails acceptance without losing input or starting a request',
    () async {
      final limited = ChatOutboxStorage(storage, operationLimit: 0);
      final repository = FixtureRepository();
      final cubit = ChatConversationCubit(
        repository,
        const NoopChatRealtime(),
        messageCache: cache,
        outbox: limited,
      )..bind(session, group);
      await until(() => !cubit.state.loading);
      expect(await cubit.send('fixture'), isFalse);
      expect(cubit.state.pending, isEmpty);
      expect(repository.sendIds, isEmpty);
      expect(cubit.state.failure, isNotNull);
      await cubit.close();
    },
  );

  test('lost text response uses stable UUID, disallows cancellation and duplicate retry', () async {
    final repository = FixtureRepository()..loseResponse = true;
    final cubit = ChatConversationCubit(
      repository,
      const NoopChatRealtime(),
      messageCache: cache,
      outbox: outbox,
    )..bind(session, group);
    await until(() => !cubit.state.loading);
    await cubit.send('fixture');
    await until(
      () => cubit.state.pending.single.status == ChatUploadState.uncertain,
    );
    final id = cubit.state.pending.single.clientMessageId;
    expect(
      RegExp(
        r'^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$',
      ).hasMatch(id),
      isTrue,
    );
    await cubit.cancelPending(id);
    expect(cubit.state.pending, hasLength(1));
    await Future.wait([cubit.retryMedia(id), cubit.retryMedia(id)]);
    expect(repository.sendIds, [id, id]);
    expect(cubit.state.messages, hasLength(1));
    expect(cubit.state.pending, isEmpty);
    await cubit.close();
  });

  test('restart restores uncertain media without replay and retries only finalization', () async {
    final file = await outbox.ownMedia(scope, jpeg);
    final operation = ChatOutboxOperation(
      id: '77777777-7777-4777-8777-777777777777',
      type: 'IMAGE',
      createdAt: DateTime.now().toUtc(),
      file: file,
      mimeType: 'image/jpeg',
      sizeBytes: 4,
      uploadId: '88888888-8888-4888-8888-888888888888',
      submitted: true,
      phase: 'finalizing',
    );
    await outbox.save(scope, operation);
    final repository = FixtureRepository();
    final cubit = ChatConversationCubit(
      repository,
      const NoopChatRealtime(),
      messageCache: cache,
      outbox: outbox,
    )..bind(session, group);
    await until(() => !cubit.state.loading);
    expect(cubit.state.pending.single.status, ChatUploadState.uncertain);
    expect(repository.finalizeCalls, 0);
    await cubit.retryMedia(operation.id);
    expect(repository.finalizeCalls, 1);
    expect(repository.uploadCalls, 0);
    expect(repository.cancelCalls, 0);
    expect(cubit.state.pending, isEmpty);
    expect(await outbox.mediaFile(file).exists(), isFalse);
    await cubit.close();
  });

  test(
    'private data survives actual database reopening but grants never do',
    () async {
      final disk = await ChatCacheDatabase.open(
        Directory('${directory.path}/disk'),
      );
      disk.bindSession(session);
      await disk.ready;
      disk.grant(scope);
      await ChatMessageCache(disk)
          .write(scope, ChatMessagePage(messages: [message(1)]));
      await ChatOutboxStorage(disk).save(
        scope,
        ChatOutboxOperation(
          id: '77777777-7777-4777-8777-777777777777',
          type: 'TEXT',
          createdAt: DateTime.now().toUtc(),
          text: 'fixture',
        ),
      );
      await disk.close();
      final reopened = await ChatCacheDatabase.open(
        Directory('${directory.path}/disk'),
      );
      reopened.bindSession(session);
      await reopened.ready;
      expect(await ChatMessageCache(reopened).read(scope), isNull);
      reopened.grant(scope);
      expect(
        (await ChatMessageCache(reopened).read(scope))!.messages,
        hasLength(1),
      );
      expect(await ChatOutboxStorage(reopened).restore(scope), hasLength(1));
      await reopened.close();
    },
  );

  test('access denial clears visible history, files and pending; late sends are rejected', () async {
    final gate = Completer<ChatMessage>();
    final repository = FixtureRepository()
      ..page = ChatMessagePage(messages: [message(1)])
      ..sendGate = gate;
    final cubit = ChatConversationCubit(
      repository,
      const NoopChatRealtime(),
      messageCache: cache,
      outbox: outbox,
    )..bind(session, group);
    await until(() => !cubit.state.loading);
    await cubit.send('fixture');
    await until(() => repository.sendIds.isNotEmpty);
    final id = repository.sendIds.single;
    await storage.revoke(scope);
    expect(cubit.state.accessLost, isTrue);
    expect(cubit.state.messages, isEmpty);
    expect(cubit.state.pending, isEmpty);
    gate.complete(message(3, clientId: id));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(cubit.state.messages, isEmpty);
    expect(
      await storage.records.count(
        storage.database,
        filter: Filter.equals('scope', scope.key),
      ),
      0,
    );
    await cubit.close();
  });

  test(
    'logout cleanup is scoped and cannot delete another user records',
    () async {
      await cache.write(scope, ChatMessagePage(messages: [message(1)]));
      const next = FeatureSessionScope(
        userId: '99999999-9999-4999-8999-999999999999',
        workspaceId: workspace,
        membershipId: membership,
        timezone: 'Etc/UTC',
        role: WorkspaceRole.employee,
      );
      const nextScope = ChatCacheScope(
        '99999999-9999-4999-8999-999999999999',
        workspace,
        group,
      );
      storage.bindSession(next);
      storage.grant(nextScope);
      await cache.write(nextScope, ChatMessagePage(messages: [message(2)]));
      await storage.ready;
      expect(await cache.read(scope), isNull);
      expect((await cache.read(nextScope))!.messages.single.id, message(2).id);
      expect(
        await storage.records.count(
          storage.database,
          filter: Filter.equals('user', user),
        ),
        0,
      );
      expect(
        await cache.read(
          const ChatCacheScope(
            '99999999-9999-4999-8999-999999999999',
            'other-workspace',
            group,
          ),
        ),
        isNull,
      );
    },
  );

  test('image/voice hits and concurrent consumers share URL and transfer; corruption refetches', () async {
    final repository = FixtureRepository();
    final adapter = FixtureDownloadAdapter();
    final media = ChatMediaCache(
      storage,
      downloadClient: Dio()..httpClientAdapter = adapter,
    );
    final image = message(1, type: 'IMAGE');
    final files = await Future.wait([
      media.resolve(scope, image, repository),
      media.resolve(scope, image, repository),
    ]);
    expect(files.first.path, files.last.path);
    await media.resolve(scope, image, repository);
    expect(repository.urlCalls, 1);
    expect(adapter.calls, 1);
    adapter.bytes = Uint8List.fromList('OggS'.codeUnits);
    await media.resolve(scope, message(2, type: 'VOICE'), repository);
    await media.resolve(scope, message(2, type: 'VOICE'), repository);
    expect(repository.urlCalls, 2);
    expect(adapter.calls, 2);
    adapter.bytes = jpeg;
    await files.first.writeAsBytes([0, 0, 0, 0]);
    await media.resolve(scope, image, repository);
    expect(repository.urlCalls, 3);
    expect(adapter.calls, 3);
    expect(
      adapter.headers.every(
        (headers) =>
            !headers.keys.any((name) => name.toLowerCase() == 'authorization'),
      ),
      isTrue,
    );
    media.close();
  });

  test(
    'expired URLs retry once and incomplete downloads leave no cached entry',
    () async {
      final repository = FixtureRepository();
      final adapter = FixtureDownloadAdapter()..denials = 1;
      final media = ChatMediaCache(
        storage,
        downloadClient: Dio()..httpClientAdapter = adapter,
      );
      await media.resolve(scope, message(1, type: 'IMAGE'), repository);
      expect(repository.urlCalls, 2);
      expect(adapter.calls, 2);
      adapter.denials = 3;
      await expectLater(
        media.resolve(scope, message(2, type: 'IMAGE'), repository),
        throwsA(isA<DioException>()),
      );
      expect(repository.urlCalls, 4);
      adapter.denials = 0;
      adapter.bytes = Uint8List.fromList([0xff]);
      await expectLater(
        media.resolve(scope, message(3, type: 'IMAGE'), repository),
        throwsFormatException,
      );
      expect(
        await storage.records.count(
          storage.database,
          filter: Filter.equals('kind', 'media'),
        ),
        1,
      );
      expect(
        (await directory.list().toList()).where(
          (entity) => entity.path.endsWith('.part'),
        ),
        isEmpty,
      );
      media.close();
    },
  );

  test(
    'media LRU honors pins and clear never removes unresolved outbox files',
    () async {
      final repository = FixtureRepository();
      final media = ChatMediaCache(
        storage,
        byteLimit: 8,
        downloadClient: Dio()..httpClientAdapter = FixtureDownloadAdapter(),
      );
      final first = await media.resolve(
        scope,
        message(1, type: 'IMAGE'),
        repository,
      );
      media.pin(first);
      final second = await media.resolve(
        scope,
        message(2, type: 'IMAGE'),
        repository,
      );
      await media.resolve(scope, message(3, type: 'IMAGE'), repository);
      expect(await first.exists(), isTrue);
      expect(await second.exists(), isFalse);
      final pending = await outbox.ownMedia(scope, jpeg);
      await outbox.save(
        scope,
        ChatOutboxOperation(
          id: '77777777-7777-4777-8777-777777777777',
          type: 'IMAGE',
          createdAt: DateTime.now().toUtc(),
          file: pending,
          mimeType: 'image/jpeg',
          sizeBytes: 4,
        ),
      );
      await media.clear();
      expect(await first.exists(), isTrue);
      expect(await outbox.mediaFile(pending).exists(), isTrue);
      media.unpin(first);
      await media.clear();
      expect(await first.exists(), isFalse);
      media.close();
    },
  );

  test('bounded message retention evicts old pages without changing cursor meaning', () async {
    final limited = ChatMessageCache(storage, messageLimit: 2);
    await limited.write(
      scope,
      ChatMessagePage(messages: [message(1)], nextCursor: 'end'),
      cursor: 'older',
    );
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await limited.write(
      scope,
      ChatMessagePage(messages: [message(3), message(2)], nextCursor: 'older'),
    );
    expect(await limited.read(scope, cursor: 'older'), isNull);
    expect((await limited.read(scope))!.nextCursor, 'older');
  });

  test(
    'download concurrency is bounded and revocation cancels stale consumers',
    () async {
      final repository = FixtureRepository();
      final adapter = FixtureDownloadAdapter()..gate = Completer<void>();
      final media = ChatMediaCache(
        storage,
        maxTransfers: 1,
        downloadClient: Dio()..httpClientAdapter = adapter,
      );
      final first = media.resolve(scope, message(1, type: 'IMAGE'), repository);
      final second = media.resolve(
        scope,
        message(2, type: 'IMAGE'),
        repository,
      );
      final failures = Future.wait([
        expectLater(first, throwsA(anything)),
        expectLater(second, throwsA(anything)),
      ]);
      await until(() => adapter.calls == 1);
      expect(repository.urlCalls, 1);
      await storage.revoke(scope);
      adapter.gate!.complete();
      await failures;
      expect(await media.size(), 0);
      expect(
        (await directory.list().toList()).where(
          (file) => file.path.endsWith('.bin') || file.path.endsWith('.part'),
        ),
        isEmpty,
      );
      media.close();
    },
  );

  test(
    'completed outbox playback file survives until its lease is released',
    () async {
      final filename = await outbox.ownMedia(scope, jpeg);
      final operation = ChatOutboxOperation(
        id: '77777777-7777-4777-8777-777777777777',
        type: 'IMAGE',
        createdAt: DateTime.now().toUtc(),
        file: filename,
      );
      await outbox.save(scope, operation);
      final file = outbox.mediaFile(filename);
      storage.pin(file);
      await outbox.remove(scope, operation);
      expect(await file.exists(), isTrue);
      storage.unpin(file);
      await until(() => !file.existsSync());
    },
  );

  test(
    'archived scope cannot accept or automatically replay queued messages',
    () async {
      final operation = ChatOutboxOperation(
        id: '77777777-7777-4777-8777-777777777777',
        type: 'TEXT',
        createdAt: DateTime.now().toUtc(),
        text: 'fixture',
      );
      await outbox.save(scope, operation);
      storage.grant(scope, archived: true);
      final repository = FixtureRepository();
      final cubit = ChatConversationCubit(
        repository,
        const NoopChatRealtime(),
        messageCache: cache,
        outbox: outbox,
      )..bind(session, group);
      await until(() => !cubit.state.loading);
      expect(await cubit.send('fixture'), isFalse);
      expect(repository.sendIds, isEmpty);
      expect(cubit.state.pending.single.status, ChatUploadState.queued);
      await cubit.close();
    },
  );

  test('controlled cold/warm opening and media request counts', () async {
    final repository = FixtureRepository()
      ..delay = const Duration(milliseconds: 80)
      ..page = ChatMessagePage(messages: [message(1)]);
    final cold = Stopwatch()..start();
    var cubit = ChatConversationCubit(
      repository,
      const NoopChatRealtime(),
      messageCache: cache,
      outbox: outbox,
    )..bind(session, group);
    await until(() => cubit.state.messages.isNotEmpty);
    cold.stop();
    await cubit.close();
    final warm = Stopwatch()..start();
    cubit = ChatConversationCubit(
      repository,
      const NoopChatRealtime(),
      messageCache: cache,
      outbox: outbox,
    )..bind(session, group);
    await until(() => cubit.state.messages.isNotEmpty);
    warm.stop();
    expect(warm.elapsed < cold.elapsed, isTrue);
    final adapter = FixtureDownloadAdapter();
    final media = ChatMediaCache(
      storage,
      downloadClient: Dio()..httpClientAdapter = adapter,
    );
    await media.resolve(scope, message(2, type: 'IMAGE'), repository);
    final coldUrls = repository.urlCalls;
    final coldDownloads = adapter.calls;
    await media.resolve(scope, message(2, type: 'IMAGE'), repository);
    // Safe aggregate-only fixture measurement, no private content or file paths.
    // ignore: avoid_print
    print(
      'CHAT_FIXTURE cold_ms=${cold.elapsedMilliseconds} warm_ms=${warm.elapsedMilliseconds} cold_urls=$coldUrls cold_downloads=$coldDownloads warm_extra_urls=${repository.urlCalls - coldUrls} warm_extra_downloads=${adapter.calls - coldDownloads}',
    );
    await cubit.close();
    media.close();
    await Future<void>.delayed(const Duration(milliseconds: 90));
  });

  testWidgets('all four pending types render before canonical confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              for (final type in PendingChatMediaType.values)
                PendingMediaBubble(
                  pending: PendingChatMessage(
                    clientMessageId: type.name,
                    mediaType: type,
                    status: ChatUploadState.queued,
                    text: 'pending fixture',
                    location: const ChatLocation(latitude: 0, longitude: 0),
                    durationMs: 1000,
                  ),
                  onRetry: (_) async {},
                  onCancel: (_) async {},
                ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('pending fixture'), findsOneWidget);
    expect(find.text('Image'), findsOneWidget);
    expect(find.text('Voice message'), findsOneWidget);
    expect(find.text('Shared location'), findsOneWidget);
    expect(find.text('Queued'), findsNWidgets(4));
  });
}

class FixtureRepository extends ChatRepository {
  ChatMessagePage page = const ChatMessagePage(messages: []);
  ChatMessagePage olderPage = const ChatMessagePage(messages: []);
  Future<ChatMessagePage>? nextPage;
  Duration delay = Duration.zero;
  Completer<ChatMessage>? sendGate;
  bool loseResponse = false;
  final List<String> sendIds = [];
  final firstSendStarted = Completer<void>();
  final Map<String, ChatMessage> committed = {};
  int olderCalls = 0,
      urlCalls = 0,
      finalizeCalls = 0,
      uploadCalls = 0,
      cancelCalls = 0;
  int listCalls = 0;
  @override
  Future<ChatMessagePage> listMessages(
    String workspaceId,
    String groupId, {
    String? cursor,
    int limit = 30,
  }) async {
    listCalls++;
    if (cursor != null) {
      olderCalls++;
      return olderPage;
    }
    if (nextPage != null) return await nextPage!;
    await Future<void>.delayed(delay);
    return page;
  }

  @override
  Future<ChatMessage> sendMessage(
    String workspaceId,
    String groupId, {
    required String text,
    required String clientMessageId,
    String? replyToMessageId,
  }) async {
    sendIds.add(clientMessageId);
    if (!firstSendStarted.isCompleted) firstSendStarted.complete();
    if (sendGate != null) {
      final result = await sendGate!.future;
      committed[clientMessageId] = result;
      return result;
    }
    final result = committed.putIfAbsent(
      clientMessageId,
      () => message(20 + committed.length, clientId: clientMessageId),
    );
    if (loseResponse) {
      loseResponse = false;
      throw const ApiException(message: 'Fixture lost response');
    }
    return result;
  }

  @override
  Future<ChatMessage> sendLocation(
    String workspaceId,
    String groupId, {
    required ChatLocation location,
    required String clientMessageId,
  }) async {
    sendIds.add(clientMessageId);
    return committed.putIfAbsent(
      clientMessageId,
      () => message(
        40 + committed.length,
        type: 'LOCATION',
        clientId: clientMessageId,
      ),
    );
  }

  @override
  Future<ChatMessage> finalizeUpload(
    String workspaceId,
    String groupId, {
    required String type,
    required String uploadId,
    required String clientMessageId,
  }) async {
    finalizeCalls++;
    return message(30, type: type, clientId: clientMessageId);
  }

  @override
  Future<void> cancelUpload(
    String workspaceId,
    String groupId,
    String uploadId,
  ) async {
    cancelCalls++;
  }

  @override
  Future<ChatMediaUrl> mediaUrl(
    String workspaceId,
    String groupId,
    String messageId,
  ) async {
    urlCalls++;
    return ChatMediaUrl(
      url: Uri.parse('https://fixture.invalid/media'),
      expiresAt: DateTime.now().add(const Duration(minutes: 1)),
    );
  }

  @override
  Future<void> markRead(
    String workspaceId,
    String groupId,
    String messageId,
  ) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unused fixture operation');
}

class GatedMessageCache extends ChatMessageCache {
  GatedMessageCache(super.storage);

  bool blockNextWrite = false;
  final writeStarted = Completer<void>();
  final releaseWrite = Completer<void>();

  @override
  Future<void> write(
    ChatCacheScope scope,
    ChatMessagePage page, {
    String? cursor,
  }) async {
    if (blockNextWrite) {
      blockNextWrite = false;
      writeStarted.complete();
      await releaseWrite.future;
    }
    await super.write(scope, page, cursor: cursor);
  }
}

class FixtureDownloadAdapter implements HttpClientAdapter {
  int calls = 0, denials = 0;
  Uint8List bytes = jpeg;
  Completer<void>? gate;
  final List<Map<String, dynamic>> headers = [];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    headers.add(Map.of(options.headers));
    if (denials-- > 0) return ResponseBody.fromString('', 403);
    if (gate != null) await gate!.future;
    await Future<void>.delayed(const Duration(milliseconds: 2));
    return ResponseBody.fromBytes(
      bytes,
      200,
      headers: {
        'content-type': ['application/octet-stream'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
