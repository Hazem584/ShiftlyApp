import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/chat/data/mock_chat_repository.dart';
import 'package:shiftly/features/chat/data/stream/stream_chat_connection.dart';
import 'package:shiftly/features/chat/data/stream/stream_chat_history.dart';
import 'package:shiftly/features/chat/data/stream/stream_chat_mapper.dart';
import 'package:shiftly/features/chat/data/stream/stream_chat_media.dart';
import 'package:shiftly/features/chat/data/stream/stream_chat_realtime.dart';
import 'package:shiftly/features/chat/data/stream/stream_chat_repository.dart';
import 'package:shiftly/features/chat/data/stream/stream_chat_request.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as sdk;

const workspace = '22222222-2222-4222-8222-222222222222';
const group = '33333333-3333-4333-8333-333333333333';
const member = '44444444-4444-4444-8444-444444444444';
const session = FeatureSessionScope(
  userId: '11111111-1111-4111-8111-111111111111',
  workspaceId: workspace,
  membershipId: member,
  timezone: 'Africa/Cairo',
  role: WorkspaceRole.employee,
);
String messageId(int i) =>
    '55555555-5555-4555-8555-${i.toString().padLeft(12, '0')}';
sdk.Message message(int i) => sdk.Message(
  id: messageId(i),
  text: 'Message $i',
  user: sdk.User(id: member, name: 'Hazem'),
  createdAt: DateTime.utc(2026, 11, 14, 10, i),
);
Dio apiWith(FutureOr<Object?> Function(RequestOptions) respond) {
  final api = Dio(BaseOptions(baseUrl: 'https://shiftly.invalid/api/v1'));
  api.interceptors.add(
    InterceptorsWrapper(
      onRequest: (request, handler) async {
        handler.resolve(
          Response(
            requestOptions: request,
            data: await respond(request),
            statusCode: 200,
          ),
        );
      },
    ),
  );
  return api;
}

Map<String, Object> auth({String membership = member}) => {
  'enabled': true,
  'apiKey': 'public-test-key',
  'token': 'test-token',
  'userId': membership,
  'workspaceId': workspace,
  'channelType': 'shiftly',
};

void main() {
  test(
    'disabled provider uses existing chat without connecting to Stream',
    () async {
      var requests = 0;
      final connection = StreamChatConnection(
        apiWith((_) {
          requests++;
          return {'enabled': false};
        }),
        persist: false,
      );
      connection.bind(session);
      final repository = StreamChatRepository(
        const MockChatRepository(),
        connection,
      );
      expect(await repository.listGroups(workspace), isEmpty);
      expect(await connection.clientFor(workspace), isNull);
      expect(requests, 1);
      await connection.dispose();
    },
  );

  test(
    'invalid membership in token response never connects a different user',
    () async {
      var constructed = false;
      final connection = StreamChatConnection(
        apiWith(
          (request) => request.method == 'GET'
              ? {'enabled': true}
              : auth(membership: messageId(1)),
        ),
        persist: false,
        clientFactory: (_) {
          constructed = true;
          return TestClient();
        },
      );
      connection.bind(session);
      await expectLater(connection.clientFor(workspace), throwsFormatException);
      expect(constructed, isFalse);
      await connection.dispose();
    },
  );

  test(
    'concurrent requests share one authenticated connection and refresh tokens',
    () async {
      var configurations = 0, sessions = 0;
      final client = TestClient();
      final connection = StreamChatConnection(
        apiWith((request) {
          if (request.method == 'GET') {
            configurations++;
            return {'enabled': true};
          }
          sessions++;
          return auth();
        }),
        persist: false,
        clientFactory: (_) => client,
      )..bind(session);
      final clients = await Future.wait(
        List.generate(10, (_) => connection.clientFor(workspace)),
      );
      expect(clients.every((item) => identical(item, client)), isTrue);
      expect(configurations, 1);
      expect(sessions, 1);
      expect(client.connections, 1);
      expect(await client.tokenProvider!(member), 'test-token');
      expect(sessions, 2);
      connection.bind(null);
      await expectLater(client.tokenProvider!(member), throwsStateError);
      await connection.dispose();
      expect(client.flushes, [true]);
    },
  );

  test('logout while authenticating rejects the delayed response', () async {
    final response = Completer<Object?>();
    final connection = StreamChatConnection(
      apiWith((_) => response.future),
      persist: false,
    )..bind(session);
    final attempt = connection.clientFor(workspace);
    final rejected = expectLater(attempt, throwsStateError);
    await Future<void>.delayed(Duration.zero);
    connection.bind(null);
    response.complete({'enabled': true});
    await rejected;
    expect(() => connection.clientFor(workspace), throwsStateError);
    await connection.dispose();
  });

  test('a burst sends directly to Stream with stable retry IDs', () async {
    final connection = TestConnection()..bind(session);
    final repository = StreamChatRepository(
      const MockChatRepository(),
      connection,
    );
    final results = await Future.wait(
      List.generate(
        20,
        (i) => repository.sendMessage(
          workspace,
          group,
          text: 'Message $i',
          clientMessageId: messageId(i),
        ),
      ),
    );
    expect(results.map((m) => m.id), List.generate(20, messageId));
    expect(
      connection.testChannel.sent.map((m) => m.id),
      List.generate(20, messageId),
    );
    expect(results.every((m) => m.clientMessageId == m.id), isTrue);
    await connection.dispose();
  });

  test(
    'history pages from Stream into old history without losing the old cursor',
    () async {
      final connection = TestConnection()..bind(session);
      connection.testChannel.page = [message(2), message(1)];
      final legacy = HistoryRepository();
      final history = StreamChatHistory(legacy, connection);
      final recent = await history.listMessages(workspace, group, limit: 3);
      expect(recent.messages.map((m) => m.id), [messageId(2), messageId(1)]);
      expect(recent.nextCursor, 'legacy:');
      final earlier = await history.listMessages(
        workspace,
        group,
        cursor: recent.nextCursor,
      );
      expect(earlier.nextCursor, 'legacy:older-page');
      await history.listMessages(workspace, group, cursor: earlier.nextCursor);
      expect(legacy.cursors, [null, 'older-page']);
      await connection.dispose();
    },
  );

  test(
    'search fallback continues in legacy history, not in Stream search',
    () async {
      final connection = TestConnection()..bind(session);
      final legacy = HistoryRepository();
      final history = StreamChatHistory(legacy, connection);
      final first = await history.searchMessages(
        workspace,
        group,
        query: 'delivery',
      );
      expect(first.nextCursor, 'legacy:search-page');
      await history.searchMessages(
        workspace,
        group,
        query: 'delivery',
        cursor: first.nextCursor,
      );
      expect(legacy.searchCursors, [null, 'search-page']);
      expect(connection.testChannel.searches, 1);
      await connection.dispose();
    },
  );

  test('incoming messages are delivered without a refresh and stop on session change', () async {
    final connection = TestConnection()..bind(session);
    final realtime = StreamChatRealtime(connection, TestLegacyRealtime());
    final received = <ChatMessage>[];
    final subscription = realtime.subscribeToMessages(
      group,
      member,
      received.add,
      () {},
    );
    connection.incoming.add(
      sdk.Event(
        type: 'message.new',
        cid: 'shiftly:$group',
        message: message(1),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(received.single.id, messageId(1));
    connection.incoming.add(
      sdk.Event(
        type: 'message.new',
        cid: 'shiftly:another-group',
        message: message(2),
      ),
    );
    connection.bind(null);
    connection.incoming.add(
      sdk.Event(
        type: 'message.new',
        cid: 'shiftly:$group',
        message: message(3),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(received, hasLength(1));
    await subscription.cancel();
    await connection.dispose();
  });

  test('attachment cache identity survives repeated SDK deserialization', () {
    sdk.Message attached() => message(1).copyWith(
      attachments: [
        sdk.Attachment(
          type: 'file',
          title: 'report.pdf',
          extraData: {
            'shiftly_attachment_id': messageId(9),
            'file_size': 1024,
            'mime_type': 'application/pdf',
          },
        ),
      ],
    );
    final first = StreamChatMapper.message(attached(), group);
    final second = StreamChatMapper.message(attached(), group);
    expect(first.attachment!.id, second.attachment!.id);
    expect(first.attachment!.mimeType, 'application/pdf');
    expect(first.type, 'DOCUMENT');
  });

  test(
    'staged uploads cannot be finalized under a different session',
    () async {
      final connection = TestConnection()..bind(session);
      final media = StreamChatMedia(connection);
      final upload = media.prepare(
        workspace,
        group,
        type: 'DOCUMENT',
        mimeType: 'application/pdf',
        sizeBytes: 10,
      );
      connection.bind(null);
      expect(
        () => media.pending(upload.uploadId, workspace, group),
        throwsStateError,
      );
      await connection.dispose();
    },
  );

  test(
    'rate limits remain retryable, revoked membership remains forbidden',
    () async {
      for (final status in [429, 403]) {
        await expectLater(
          streamChatRequest<void>(() async {
            throw sdk.StreamChatNetworkError.raw(
              code: 0,
              message: 'private diagnostic',
              statusCode: status,
            );
          }),
          throwsA(
            isA<ApiException>()
                .having(
                  (e) => e.kind,
                  'kind',
                  status == 429
                      ? FailureKind.server
                      : FailureKind.authorization,
                )
                .having(
                  (e) => e.message.contains('private diagnostic'),
                  'safe error',
                  isFalse,
                ),
          ),
        );
      }
    },
  );
}

class TestClient implements sdk.StreamChatClient {
  int connections = 0;
  final flushes = <bool>[];
  Future<String> Function(String)? tokenProvider;
  final incoming = StreamController<sdk.Event>.broadcast();
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #connectUserWithProvider) {
      connections++;
      final user = invocation.positionalArguments[0] as sdk.User;
      tokenProvider =
          invocation.positionalArguments[1] as Future<String> Function(String);
      return tokenProvider!(user.id).then((_) => sdk.OwnUser(id: user.id));
    }
    if (invocation.memberName == #on) return incoming.stream;
    if (invocation.memberName == #disconnectUser) {
      flushes.add(invocation.namedArguments[#flushChatPersistence] as bool);
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class TestChannel implements sdk.Channel {
  final sent = <sdk.Message>[];
  List<sdk.Message> page = [];
  int searches = 0;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #sendMessage) {
      final input = invocation.positionalArguments[0] as sdk.Message;
      sent.add(input);
      return Future.value(
        sdk.SendMessageResponse.fromJson({
          'message': {
            ...input.toJson(),
            'user': {'id': member, 'name': 'Hazem'},
            'created_at': DateTime.utc(2026, 11, 14).toIso8601String(),
          },
        }),
      );
    }
    if (invocation.memberName == #query) {
      return Future.value(sdk.ChannelState(messages: page));
    }
    if (invocation.memberName == #search) {
      searches++;
      return Future.value(sdk.SearchMessagesResponse.fromJson({'results': []}));
    }
    return super.noSuchMethod(invocation);
  }
}

class TestConnection extends StreamChatConnection {
  TestConnection() : super(Dio(), persist: false);
  final testClient = TestClient();
  final testChannel = TestChannel();
  final incoming = StreamController<sdk.Event>.broadcast();
  @override
  Stream<sdk.Event> get events => incoming.stream;
  @override
  Future<sdk.StreamChatClient?> clientFor(String workspaceId) async =>
      testClient;
  @override
  Future<sdk.Channel> channel(String workspaceId, String groupId) async =>
      testChannel;
  @override
  Future<void> dispose() async {
    await incoming.close();
    await super.dispose();
  }
}

class HistoryRepository extends MockChatRepository {
  final cursors = <String?>[], searchCursors = <String?>[];
  @override
  Future<ChatMessagePage> listMessages(
    String workspaceId,
    String groupId, {
    String? cursor,
    int limit = 30,
  }) async {
    cursors.add(cursor);
    return const ChatMessagePage(messages: [], nextCursor: 'older-page');
  }

  @override
  Future<ChatMessagePage> searchMessages(
    String workspaceId,
    String groupId, {
    String? query,
    bool pinned = false,
    String? cursor,
  }) async {
    searchCursors.add(cursor);
    return const ChatMessagePage(messages: [], nextCursor: 'search-page');
  }
}

class TestLegacyRealtime implements ChatLiveRealtime, ChatGroupStateRealtime {
  @override
  dynamic noSuchMethod(Invocation invocation) => TestSubscription();
}

class TestSubscription implements ChatRealtimeSubscription {
  @override
  Future<void> cancel() async {}
}
