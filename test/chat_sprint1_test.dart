import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/chat/data/api_chat_repository.dart';
import 'package:shiftly/features/chat/data/chat_models.dart';
import 'package:shiftly/features/chat/data/chat_realtime.dart';
import 'package:shiftly/features/chat/data/chat_repository.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_group_details_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';

const _workspace = '11111111-1111-4111-8111-111111111111';
const _otherWorkspace = '22222222-2222-4222-8222-222222222222';
const _group = '33333333-3333-4333-8333-333333333333';
const _membership = '44444444-4444-4444-8444-444444444444';
const _message1 = '55555555-5555-4555-8555-555555555555';
const _message2 = '66666666-6666-4666-8666-666666666666';

const _scope = FeatureSessionScope(
  userId: '77777777-7777-4777-8777-777777777777',
  workspaceId: _workspace,
  membershipId: _membership,
  timezone: 'Etc/UTC',
  role: WorkspaceRole.manager,
);

void main() {
  group('defensive models and repository contract', () {
    test('rejects malformed UUIDs and unknown message types', () {
      expect(
        () => ChatMessage.fromJson(_messageJson(id: 'bad-id')),
        throwsFormatException,
      );
      expect(
        () => ChatMessage.fromJson(_messageJson(type: 'IMAGE')),
        throwsFormatException,
      );
    });

    test('maps cursor pagination and the deployed endpoint', () async {
      late RequestOptions request;
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              request = options;
              handler.resolve(
                Response<Object?>(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'data': [_messageJson()],
                    'nextCursor': 'opaque-cursor',
                  },
                ),
              );
            },
          ),
        );
      final page = await ApiChatRepository(
        dio,
      ).listMessages(_workspace, _group, cursor: 'previous-cursor', limit: 15);
      expect(
        request.path,
        '/workspaces/$_workspace/chat/groups/$_group/messages',
      );
      expect(request.queryParameters, {
        'limit': 15,
        'cursor': 'previous-cursor',
      });
      expect(page.messages.single.id, _message1);
      expect(page.nextCursor, 'opaque-cursor');
    });
  });

  group('session isolation, pagination, idempotency, and realtime', () {
    test('ignores stale group response after workspace switch', () async {
      final repository = _FakeChatRepository();
      final first = Completer<List<ChatGroup>>();
      repository.groupLoads.add(first.future);
      repository.groupLoads.add(Future.value(const []));
      final cubit = ChatGroupsCubit(repository);
      cubit.bindSession(_scope);
      cubit.bindSession(
        const FeatureSessionScope(
          userId: '77777777-7777-4777-8777-777777777777',
          workspaceId: _otherWorkspace,
          membershipId: _membership,
          timezone: 'Etc/UTC',
          role: WorkspaceRole.manager,
        ),
      );
      await _pump();
      first.complete([_chatGroup()]);
      await _pump();
      expect(cubit.state.groups, isEmpty);
      expect(cubit.scope?.workspaceId, _otherWorkspace);
      await cubit.close();
    });

    test(
      'deduplicates cursor pages and preserves chronological order',
      () async {
        final repository = _FakeChatRepository()
          ..messageLoads.add(
            ChatMessagePage(
              messages: [
                _message(id: _message2, minute: 2),
                _message(id: _message1, minute: 1),
              ],
              nextCursor: 'older',
            ),
          )
          ..messageLoads.add(
            ChatMessagePage(messages: [_message(id: _message1, minute: 1)]),
          );
        final cubit = ChatConversationCubit(repository, _FakeRealtime());
        cubit.bind(_scope, _group);
        await _pump();
        await cubit.loadOlder();
        expect(cubit.state.messages.map((e) => e.id), [_message1, _message2]);
        await cubit.close();
      },
    );

    test('reuses one clientMessageId when retrying a failed send', () async {
      final repository = _FakeChatRepository()..sendFailures = 1;
      final cubit = ChatConversationCubit(repository, _FakeRealtime());
      cubit.bind(_scope, _group);
      await _pump();
      expect(await cubit.send('  hello  '), isFalse);
      expect(await cubit.retrySend(), isTrue);
      expect(repository.sentTexts, ['hello', 'hello']);
      expect(repository.clientIds.toSet(), hasLength(1));
      await cubit.close();
    });

    test('coalesces realtime inserts into canonical REST refreshes', () async {
      final repository = _FakeChatRepository();
      final realtime = _FakeRealtime();
      final cubit = ChatConversationCubit(repository, realtime);
      cubit.bind(_scope, _group);
      await _pump();
      final before = repository.messageLoadCount;
      realtime.insert();
      realtime.insert();
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(repository.messageLoadCount, before + 1);
      await cubit.close();
      expect(realtime.cancelled, isTrue);
    });

    test('archived group blocks member mutations', () async {
      final repository = _FakeChatRepository()
        ..details = _chatGroup(archived: true);
      final cubit = ChatGroupDetailsCubit(repository)..bind(_scope, _group);
      await _pump();
      expect(await cubit.addMembers([_membership]), isFalse);
      expect(await cubit.removeMember(_membership), isFalse);
      expect(repository.memberMutations, 0);
      await cubit.close();
    });
  });
}

Future<void> _pump() => Future<void>.delayed(const Duration(milliseconds: 20));

Map<String, Object?> _messageJson({
  String id = _message1,
  String type = 'TEXT',
}) => {
  'id': id,
  'groupId': _group,
  'type': type,
  'text': 'hello',
  'sender': {'membershipId': _membership, 'fullName': 'Sam'},
  'createdAt': '2026-10-01T10:00:00Z',
};

ChatMessage _message({required String id, required int minute}) =>
    ChatMessage.fromJson({
      ..._messageJson(id: id),
      'createdAt': '2026-10-01T10:0$minute:00Z',
    });

ChatGroup _chatGroup({bool archived = false}) => ChatGroup(
  id: _group,
  workspaceId: _workspace,
  name: 'Operations',
  memberCount: 1,
  unreadCount: 0,
  archivedAt: archived ? DateTime.utc(2026, 10, 1) : null,
  createdAt: DateTime.utc(2026, 10, 1),
  updatedAt: DateTime.utc(2026, 10, 1),
);

class _FakeRealtime implements ChatRealtime {
  void Function()? callback;
  bool cancelled = false;
  @override
  ChatRealtimeSubscription subscribeToGroup(
    String groupId,
    void Function() onInsert,
  ) {
    callback = onInsert;
    return _FakeSubscription(() => cancelled = true);
  }

  void insert() => callback?.call();
}

class _FakeSubscription implements ChatRealtimeSubscription {
  _FakeSubscription(this.onCancel);
  final void Function() onCancel;
  @override
  Future<void> cancel() async => onCancel();
}

class _FakeChatRepository implements ChatRepository {
  final groupLoads = <Future<List<ChatGroup>>>[];
  final messageLoads = <ChatMessagePage>[];
  final sentTexts = <String>[];
  final clientIds = <String>[];
  int sendFailures = 0;
  int messageLoadCount = 0;
  int memberMutations = 0;
  ChatGroup details = _chatGroup();

  @override
  Future<List<ChatGroup>> listGroups(String workspaceId) =>
      groupLoads.isEmpty ? Future.value(const []) : groupLoads.removeAt(0);
  @override
  Future<int> unreadCount(String workspaceId) async => 0;
  @override
  Future<ChatMessagePage> listMessages(
    String workspaceId,
    String groupId, {
    String? cursor,
    int limit = 30,
  }) async {
    messageLoadCount++;
    return messageLoads.isEmpty
        ? const ChatMessagePage(messages: [])
        : messageLoads.removeAt(0);
  }

  @override
  Future<ChatMessage> sendMessage(
    String workspaceId,
    String groupId, {
    required String text,
    required String clientMessageId,
    String? replyToMessageId,
  }) async {
    sentTexts.add(text);
    clientIds.add(clientMessageId);
    if (sendFailures-- > 0) throw Exception('offline');
    return _message(id: _message2, minute: 2);
  }

  @override
  Future<void> markRead(
    String workspaceId,
    String groupId,
    String messageId,
  ) async {}
  @override
  Future<ChatGroup> getGroup(String workspaceId, String groupId) async =>
      details;
  @override
  Future<ChatGroup> addMembers(
    String workspaceId,
    String groupId,
    List<String> membershipIds,
  ) async {
    memberMutations++;
    return details;
  }

  @override
  Future<void> removeMember(
    String workspaceId,
    String groupId,
    String membershipId,
  ) async {
    memberMutations++;
  }

  @override
  Future<ChatGroup> archiveGroup(String workspaceId, String groupId) async =>
      details;
  @override
  Future<ChatGroup> createGroup(
    String workspaceId, {
    required String name,
    String? description,
    required List<String> memberMembershipIds,
  }) async => details;
  @override
  Future<ChatGroup> updateGroup(
    String workspaceId,
    String groupId, {
    required String name,
    String? description,
  }) async => details;
}
