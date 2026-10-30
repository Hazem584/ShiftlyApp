import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shiftly/core/storage/platform_file.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database.dart';
import 'package:shiftly/features/chat/data/cache/chat_group_cache.dart';
import 'package:shiftly/features/chat/data/cache/chat_message_codec.dart';
import 'package:shiftly/features/chat/data/chat_broadcast_codec.dart';
import 'package:shiftly/features/chat/data/mock_chat_repository.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/domain/services/chat_document_validation.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';

import 'chat_cache_outbox_test.dart' as fixtures;

class LiveFixture implements ChatLiveRealtime {
  final List<void Function(ChatMessage)> receivers = [];
  void Function()? reconnect;
  @override
  ChatRealtimeSubscription subscribeToMessages(
    String group,
    String member,
    void Function(ChatMessage) received,
    void Function() sync,
  ) {
    receivers.add(received);
    reconnect = sync;
    return _Subscription();
  }

  @override
  ChatRealtimeSubscription subscribeToGroup(
    String group,
    void Function() refresh,
  ) => _Subscription();
  @override
  ChatRealtimeSubscription subscribeToInbox(
    String workspace,
    String member,
    void Function() refresh,
  ) => _Subscription();
}

class _Subscription implements ChatRealtimeSubscription {
  @override
  Future<void> cancel() async {}
}

class RepositoryFixture extends MockChatRepository {
  int reads = 0, uploads = 0, finalizes = 0;
  String? fileName;
  final sent = Completer<void>();
  @override
  Future<ChatMessagePage> listMessages(
    String w,
    String g, {
    String? cursor,
    int limit = 30,
  }) async {
    reads++;
    return ChatMessagePage(messages: [fixtures.message(1)]);
  }

  @override
  Future<void> markRead(String w, String g, String m) async {}
  @override
  Future<List<ChatMessage>> reconcileMessages(
    String w,
    String g,
    List<String> ids,
  ) async => [];
  @override
  Future<ChatUploadAuthorization> initiateUpload(
    String w,
    String g, {
    required String type,
    required String mimeType,
    required int sizeBytes,
    int? durationMs,
    String? fileName,
  }) async {
    uploads++;
    this.fileName = fileName;
    return ChatUploadAuthorization.fromJson({
      'uploadId': '77777777-7777-4777-8777-777777777777',
      'bucket': 'chat-media',
      'path': 'file.pdf',
      'uploadToken': 'fixture',
      'signedUploadUrl': 'https://fixture.invalid/upload',
      'expiresAt': DateTime.now()
          .toUtc()
          .add(const Duration(hours: 1))
          .toIso8601String(),
    });
  }

  @override
  Future<void> uploadSigned(
    ChatUploadAuthorization a,
    Uint8List b,
    String mime, {
    void Function(int, int)? onProgress,
    ChatUploadCancellation? cancellation,
  }) async {}
  @override
  Future<ChatMessage> finalizeUpload(
    String w,
    String g, {
    required String type,
    required String uploadId,
    required String clientMessageId,
  }) async {
    finalizes++;
    if (!sent.isCompleted) sent.complete();
    return ChatMessage(
      id: '88888888-8888-4888-8888-888888888888',
      groupId: g,
      type: type,
      clientMessageId: clientMessageId,
      sender: const ChatSender(membershipId: fixtures.membership),
      createdAt: DateTime.now(),
    );
  }
}

ChatMessage version(int revision, {String emoji = '👍'}) => ChatMessage(
  id: fixtures.message(2).id,
  groupId: fixtures.group,
  type: 'TEXT',
  text: 'Instant',
  sender: const ChatSender(membershipId: fixtures.membership),
  createdAt: DateTime.utc(2026, 10, 1, 12),
  revision: revision,
  reactions: [ChatReaction(emoji: emoji, membershipId: fixtures.membership)],
);

class LostResponseRepository extends RepositoryFixture {
  final response = Completer<ChatMessage>();
  String? outgoingId;
  @override
  Future<ChatMessage> sendMessage(
    String w,
    String g, {
    required String text,
    required String clientMessageId,
    String? replyToMessageId,
  }) {
    outgoingId = clientMessageId;
    return response.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('decodes the actual Supabase broadcast envelope and rejects cross-group payloads', () {
    final payload = ChatMessageCodec.encode(version(2));
    final decoded = ChatBroadcastCodec.decode({
      'type': 'broadcast',
      'event': 'message',
      'payload': payload,
    }, fixtures.group);
    expect(decoded.id, version(2).id);
    expect(decoded.reactions.single.emoji, '👍');
    expect(
      () => ChatBroadcastCodec.decode({
        'event': 'message',
        'payload': payload,
      }, fixtures.workspace),
      throwsFormatException,
    );
  });
  test(
    'a live confirmation finishes the outbox even if the HTTP response is lost',
    () async {
      final repo = LostResponseRepository(), live = LiveFixture();
      final cubit = ChatConversationCubit(repo, live)
        ..bind(fixtures.session, fixtures.group);
      await fixtures.until(() => !cubit.state.loading);
      expect(await cubit.send('Hello'), true);
      await fixtures.until(() => repo.outgoingId != null);
      live.receivers.single(
        ChatMessage(
          id: fixtures.message(2).id,
          groupId: fixtures.group,
          type: 'TEXT',
          text: 'Hello',
          clientMessageId: repo.outgoingId,
          sender: const ChatSender(membershipId: fixtures.membership),
          createdAt: DateTime.utc(2026, 10, 1, 12),
        ),
      );
      expect(cubit.state.pending, isEmpty);
      repo.response.completeError(StateError('Response lost'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(cubit.state.pending, isEmpty);
      await cubit.close();
    },
  );
  test('live messages appear immediately without another HTTP list request; old versions cannot roll reactions back', () async {
    final repo = RepositoryFixture(), live = LiveFixture();
    final cubit = ChatConversationCubit(repo, live)
      ..bind(fixtures.session, fixtures.group);
    await fixtures.until(() => !cubit.state.loading);
    expect(repo.reads, 1);
    live.receivers.single(version(2, emoji: '❤️'));
    expect(cubit.state.messages.last.reactions.single.emoji, '❤️');
    expect(repo.reads, 1);
    live.receivers.single(version(1));
    expect(cubit.state.messages.last.revision, 2);
    await cubit.load(refresh: true);
    expect(cubit.state.messages.last.revision, 2);
    await cubit.close();
  });
  test(
    'late callbacks from an old group binding cannot alter current state',
    () async {
      final repo = RepositoryFixture(), live = LiveFixture();
      final cubit = ChatConversationCubit(repo, live)
        ..bind(fixtures.session, fixtures.group);
      await fixtures.until(() => !cubit.state.loading);
      final old = live.receivers.single;
      cubit.bind(null, fixtures.group);
      old(version(9));
      expect(cubit.state.messages, isEmpty);
      await cubit.close();
    },
  );
  test('reaction and document filename survive persisted message codec', () {
    final message = ChatMessage(
      id: fixtures.message(2).id,
      groupId: fixtures.group,
      type: 'DOCUMENT',
      sender: const ChatSender(membershipId: fixtures.membership),
      createdAt: DateTime.utc(2026),
      revision: 4,
      reactions: [
        const ChatReaction(emoji: '❤️', membershipId: fixtures.membership),
      ],
      attachment: const ChatAttachment(
        id: '66666666-6666-4666-8666-666666666666',
        category: 'DOCUMENT',
        mimeType: 'application/pdf',
        sizeBytes: 25,
        fileName: 'report.pdf',
      ),
    );
    final decoded = ChatMessageCodec.decode([ChatMessageCodec.encode(message)])
        .single;
    expect(decoded.reactions, message.reactions);
    expect(decoded.revision, 4);
    expect(decoded.attachment?.fileName, 'report.pdf');
  });
  test(
    'document validation allows known formats, limits sizes, and rejects paths',
    () {
      final data = Uint8List.fromList([1, 2]);
      expect(ChatDocumentValidation.valid(data, 'report.xlsx'), true);
      expect(ChatDocumentValidation.valid(data, '../report.pdf'), false);
      expect(ChatDocumentValidation.valid(data, 'run.exe'), false);
      expect(
        ChatDocumentValidation.valid(
          Uint8List(10 * 1024 * 1024 + 1),
          'report.pdf',
        ),
        false,
      );
    },
  );
  test(
    'document uses the existing upload queue and preserves its filename',
    () async {
      final repo = RepositoryFixture();
      final cubit = ChatConversationCubit(repo, LiveFixture())
        ..bind(fixtures.session, fixtures.group);
      await fixtures.until(() => !cubit.state.loading);
      expect(
        await cubit.sendDocument(
          Uint8List.fromList('%PDF-1.7\n%%EOF'.codeUnits),
          'report.pdf',
        ),
        isNotNull,
      );
      await fixtures.until(
        () =>
            repo.finalizes == 1 ||
            cubit.state.pending.any((p) => p.failure != null),
      );
      expect(repo.uploads, 1);
      expect(repo.fileName, 'report.pdf');
      expect(repo.finalizes, 1);
      await cubit.close();
    },
  );
  test(
    'group cache restores the current user only and is purged at logout',
    () async {
      final dir = await Directory.systemTemp.createTemp('shiftly-live-');
      final db = await databaseFactoryMemory.openDatabase(
        'live-chat-${DateTime.now().microsecondsSinceEpoch}',
      );
      final storage = ChatCacheDatabase(db, ChatStorageDirectory(dir.path))
        ..bindSession(fixtures.session);
      final cache = ChatGroupCache(storage);
      await storage.ready;
      await cache.write(fixtures.session, (
        groups: [
          ChatGroup(
            id: fixtures.group,
            workspaceId: fixtures.workspace,
            name: 'Team',
            memberCount: 2,
            unreadCount: 1,
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        ],
        unreadCount: 1,
      ));
      expect((await cache.read(fixtures.session))?.groups.single.name, 'Team');
      storage.bindSession(null);
      await storage.ready;
      expect(await cache.read(fixtures.session), isNull);
      await storage.close();
      await dir.delete(recursive: true);
    },
  );
}
