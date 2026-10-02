import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/chat/data/api_chat_repository.dart';
import 'package:shiftly/features/chat/data/chat_models.dart';
import 'package:shiftly/features/chat/data/chat_realtime.dart';
import 'package:shiftly/features/chat/data/chat_repository.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_group_details_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/chat/presentation/screens/chat_groups_screen.dart';
import 'package:shiftly/features/employees/data/employee_repository.dart';

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
                    'hasMore': true,
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

    test(
      'parses list envelope, member wrappers, and _count fallback',
      () async {
        final group = ChatGroup.fromJson({
          ..._groupJson(),
          '_count': {'members': 2},
          'members': [
            {
              'joinedAt': '2026-10-01T10:00:00Z',
              'membership': {
                'id': _membership,
                'role': 'MANAGER',
                'profile': {'id': _message2, 'fullName': 'Sam'},
              },
            },
          ],
        });
        expect(group.memberCount, 2);
        expect(group.members.single.membershipId, _membership);
        expect(group.members.single.fullName, 'Sam');
        final messageJson = _messageJson()..remove('sender');
        final message = ChatMessage.fromJson({
          ...messageJson,
          'senderMembership': {
            'id': _membership,
            'profile': {'id': _message2, 'fullName': 'Taylor'},
          },
        });
        expect(message.sender.fullName, 'Taylor');
      },
    );

    test('validates add/remove acknowledgements and request bodies', () async {
      final requests = <RequestOptions>[];
      final responses = <Object?>[
        {'addedCount': 1},
        {'removed': true},
      ];
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add(options);
              handler.resolve(
                Response<Object?>(
                  requestOptions: options,
                  statusCode: 200,
                  data: responses.removeAt(0),
                ),
              );
            },
          ),
        );
      final repository = ApiChatRepository(dio);
      await repository.addMembers(_workspace, _group, [
        _membership,
        _membership,
      ]);
      await repository.removeMember(_workspace, _group, _membership);
      expect(requests.first.data, {
        'membershipIds': [_membership],
      });
      expect(requests.last.path, endsWith('/members/$_membership'));
    });

    test(
      'rejects malformed successful acknowledgements as typed errors',
      () async {
        final dio = Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) => handler.resolve(
                Response<Object?>(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'addedCount': -1},
                ),
              ),
            ),
          );
        expect(
          ApiChatRepository(dio).addMembers(_workspace, _group, [_membership]),
          throwsA(isA<ApiException>()),
        );
      },
    );

    test('preserves typed API code and requestId', () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) => handler.reject(
              DioException(
                requestOptions: options,
                response: Response<Object?>(
                  requestOptions: options,
                  statusCode: 409,
                  data: {
                    'code': 'CHAT_GROUP_ARCHIVED',
                    'message': 'provider detail must not be displayed',
                    'requestId': 'req-chat-1',
                  },
                ),
                type: DioExceptionType.badResponse,
              ),
            ),
          ),
        );
      try {
        await ApiChatRepository(dio).archiveGroup(_workspace, _group);
        fail('Expected ApiException');
      } on ApiException catch (error) {
        expect(error.code, 'CHAT_GROUP_ARCHIVED');
        expect(error.requestId, 'req-chat-1');
        expect(error.message, 'This chat group is archived and read only.');
      }
    });

    test(
      'create trims values, omits empty description, and parses count',
      () async {
        late RequestOptions request;
        final dio = Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                request = options;
                handler.resolve(
                  Response<Object?>(
                    requestOptions: options,
                    statusCode: 201,
                    data: {..._groupJson(), 'memberCount': 1},
                  ),
                );
              },
            ),
          );
        final group = await ApiChatRepository(dio).createGroup(
          _workspace,
          name: '  Operations  ',
          description: '   ',
          memberMembershipIds: [_membership, _membership],
        );
        expect(group.memberCount, 1);
        expect(request.data, {
          'name': 'Operations',
          'memberMembershipIds': [_membership],
        });
      },
    );
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
      'successful update uses canonical refresh and retains metadata',
      () async {
        final canonical = _chatGroup(memberCount: 9, unreadCount: 42);
        final repository = _FakeChatRepository()
          ..groupLoads.add(Future.value([canonical]))
          ..groupLoads.add(Future.value([canonical]));
        final cubit = ChatGroupsCubit(repository)..bindSession(_scope);
        await _pump();
        expect(
          await cubit.update(_group, name: 'Renamed', description: ''),
          ChatMutationResult.success,
        );
        expect(cubit.state.groups.single.memberCount, 9);
        expect(cubit.state.groups.single.unreadCount, 42);
        await cubit.close();
      },
    );

    test(
      'successful mutation retains data when canonical refresh fails',
      () async {
        final canonical = _chatGroup(memberCount: 4, unreadCount: 3);
        final repository = _FakeChatRepository()
          ..groupLoads.add(Future.value([canonical]))
          ..groupLoads.add(
            Future<List<ChatGroup>>.delayed(
              const Duration(milliseconds: 50),
              () => throw Exception('offline'),
            ),
          );
        final cubit = ChatGroupsCubit(repository)..bindSession(_scope);
        await _pump();
        expect(await cubit.archive(_group), ChatMutationResult.success);
        expect(cubit.state.groups.single, canonical);
        expect(cubit.state.failure, isNotNull);
        await cubit.close();
      },
    );

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

    test('member mutation invalidates the canonical group list', () async {
      final repository = _FakeChatRepository();
      var invalidations = 0;
      final cubit = ChatGroupDetailsCubit(
        repository,
        onChanged: () => invalidations++,
      )..bind(_scope, _group);
      await _pump();
      expect(await cubit.addMembers([_message2]), isTrue);
      expect(invalidations, 1);
      expect(repository.memberMutations, 1);
      await cubit.close();
    });
  });

  group('chat group editor widgets', () {
    testWidgets('uses exact limits and manager-only create control', (
      tester,
    ) async {
      final managerCubit = ChatGroupsCubit(_FakeChatRepository())
        ..bindSession(_scope);
      await tester.pumpWidget(
        RepositoryProvider<EmployeeRepository>.value(
          value: _FakeEmployeeRepository(),
          child: BlocProvider.value(
            value: managerCubit,
            child: const MaterialApp(home: ChatGroupsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('create-chat-group')), findsOneWidget);
      await tester.tap(find.byKey(const Key('create-chat-group')));
      await tester.pumpAndSettle();
      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields.map((field) => field.maxLength), [80, 500]);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await managerCubit.close();

      final employeeCubit = ChatGroupsCubit(_FakeChatRepository())
        ..bindSession(
          const FeatureSessionScope(
            userId: '77777777-7777-4777-8777-777777777777',
            workspaceId: _workspace,
            membershipId: _membership,
            timezone: 'Etc/UTC',
            role: WorkspaceRole.employee,
          ),
        );
      await tester.pumpWidget(
        RepositoryProvider<EmployeeRepository>.value(
          value: _FakeEmployeeRepository(),
          child: BlocProvider.value(
            value: employeeCubit,
            child: const MaterialApp(home: ChatGroupsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('create-chat-group')), findsNothing);
      await employeeCubit.close();
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

ChatGroup _chatGroup({
  bool archived = false,
  int memberCount = 1,
  int unreadCount = 0,
}) => ChatGroup(
  id: _group,
  workspaceId: _workspace,
  name: 'Operations',
  memberCount: memberCount,
  unreadCount: unreadCount,
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
  Future<void> addMembers(
    String workspaceId,
    String groupId,
    List<String> membershipIds,
  ) async {
    memberMutations++;
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
  Future<void> archiveGroup(String workspaceId, String groupId) async {}
  @override
  Future<ChatGroup> createGroup(
    String workspaceId, {
    required String name,
    String? description,
    required List<String> memberMembershipIds,
  }) async => details;
  @override
  Future<void> updateGroup(
    String workspaceId,
    String groupId, {
    required String name,
    String? description,
  }) async {}
}

class _FakeEmployeeRepository implements EmployeeRepository {
  @override
  Future<EmployeePage> listEmployees({
    required String workspaceId,
    String search = '',
    EmployeeStatusFilter? status,
    int page = 1,
    int limit = 20,
  }) async => EmployeePage(
    data: const [],
    page: page,
    limit: limit,
    total: 0,
    totalPages: 1,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, Object?> _groupJson() => {
  'id': _group,
  'workspaceId': _workspace,
  'name': 'Operations',
  'description': null,
  'archivedAt': null,
  'createdAt': '2026-10-01T10:00:00Z',
  'updatedAt': '2026-10-01T10:00:00Z',
};
