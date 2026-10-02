import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/models/employee.dart';
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
import 'package:shiftly/features/chat/presentation/screens/chat_screen.dart';
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
    test('rejects malformed UUIDs and retains unknown message types', () {
      expect(
        () => ChatMessage.fromJson(_messageJson(id: 'bad-id')),
        throwsFormatException,
      );
      final unknown = ChatMessage.fromJson(_messageJson(type: 'FUTURE_TYPE'));
      expect(unknown.type, 'FUTURE_TYPE');
      expect(unknown.text, 'hello');
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

  group('monotonic read positions', () {
    test('successful mark-read refreshes shared group state once', () async {
      var changes = 0;
      final repository = _FakeChatRepository()
        ..messageLoads.add(
          ChatMessagePage(messages: [_message(id: _message1, minute: 1)]),
        );
      final cubit = ChatConversationCubit(
        repository,
        _FakeRealtime(),
        onChanged: () => changes++,
      )..bind(_scope, _group);
      await _pump();
      expect(changes, 1);
      await cubit.close();
    });

    test(
      'uses the message id tie-break and does not resend a confirmation',
      () async {
        final sameTime = DateTime.utc(2026, 10, 1, 10);
        final repository = _FakeChatRepository()
          ..messageLoads.add(
            ChatMessagePage(
              messages: [
                _messageAt(_message1, sameTime),
                _messageAt(_message2, sameTime),
              ],
            ),
          );
        final cubit = ChatConversationCubit(repository, _FakeRealtime())
          ..bind(_scope, _group);
        await _pump();
        expect(repository.readMessageIds, [_message2]);

        repository.messageLoads.add(
          ChatMessagePage(messages: [_messageAt(_message2, sameTime)]),
        );
        await cubit.load(refresh: true);
        await _pump();
        expect(repository.readMessageIds, [_message2]);
        await cubit.close();
      },
    );

    test(
      'failed read remains retryable on a later canonical refresh',
      () async {
        var changes = 0;
        final repository = _FakeChatRepository()
          ..messageLoads.add(
            ChatMessagePage(messages: [_message(id: _message1, minute: 1)]),
          )
          ..readResults.add(
            Future<void>.delayed(
              Duration.zero,
              () => throw Exception('offline'),
            ),
          );
        final cubit = ChatConversationCubit(
          repository,
          _FakeRealtime(),
          onChanged: () => changes++,
        )..bind(_scope, _group);
        await _pump();
        expect(changes, 0);
        repository.messageLoads.add(
          ChatMessagePage(messages: [_message(id: _message1, minute: 1)]),
        );
        await cubit.load(refresh: true);
        await _pump();
        expect(repository.readMessageIds, [_message1, _message1]);
        expect(changes, 1);
        await cubit.close();
      },
    );

    test('serializes reads and sends only a newer queued position', () async {
      final firstRead = Completer<void>();
      final repository = _FakeChatRepository()
        ..messageLoads.add(
          ChatMessagePage(messages: [_message(id: _message1, minute: 1)]),
        )
        ..readResults.add(firstRead.future);
      final cubit = ChatConversationCubit(repository, _FakeRealtime())
        ..bind(_scope, _group);
      await _pump();
      repository.messageLoads.add(
        ChatMessagePage(messages: [_message(id: _message2, minute: 2)]),
      );
      await cubit.load(refresh: true);
      expect(repository.readMessageIds, [_message1]);
      firstRead.complete();
      await _pump();
      expect(repository.readMessageIds, [_message1, _message2]);
      await cubit.close();
    });

    test('ignores an older position while a newer read is active', () async {
      final read = Completer<void>();
      final repository = _FakeChatRepository()
        ..messageLoads.add(
          ChatMessagePage(messages: [_message(id: _message2, minute: 2)]),
        )
        ..readResults.add(read.future);
      final cubit = ChatConversationCubit(repository, _FakeRealtime())
        ..bind(_scope, _group);
      await _pump();
      repository.messageLoads.add(
        ChatMessagePage(messages: [_message(id: _message1, minute: 1)]),
      );
      await cubit.load(refresh: true);
      read.complete();
      await _pump();
      expect(repository.readMessageIds, [_message2]);
      await cubit.close();
    });

    test('backwards is synchronized and not continually resent', () async {
      var changes = 0;
      final read = Completer<void>();
      final repository = _FakeChatRepository()
        ..messageLoads.add(
          ChatMessagePage(messages: [_message(id: _message1, minute: 1)]),
        )
        ..readResults.add(read.future);
      final cubit = ChatConversationCubit(
        repository,
        _FakeRealtime(),
        onChanged: () => changes++,
      )..bind(_scope, _group);
      await _pump();
      read.completeError(
        const ApiException(
          message: 'safe',
          code: 'CHAT_READ_POSITION_BACKWARDS',
        ),
      );
      await _pump();
      repository.messageLoads.add(
        ChatMessagePage(messages: [_message(id: _message1, minute: 1)]),
      );
      await cubit.load(refresh: true);
      await _pump();
      expect(changes, 1);
      expect(repository.readMessageIds, [_message1]);
      await cubit.close();
    });

    test('conflict reloads and successful retry notifies once', () async {
      var changes = 0;
      final firstRead = Completer<void>();
      final reload = Completer<ChatMessagePage>();
      final retry = Completer<void>();
      final repository = _FakeChatRepository()
        ..messageLoads.add(
          ChatMessagePage(messages: [_message(id: _message1, minute: 1)]),
        )
        ..messageLoads.add(reload.future)
        ..readResults.add(firstRead.future)
        ..readResults.add(retry.future);
      final cubit = ChatConversationCubit(
        repository,
        _FakeRealtime(),
        onChanged: () => changes++,
      )..bind(_scope, _group);
      await _pump();

      firstRead.completeError(_readConflict());
      await _pump();
      expect(repository.messageLoadCount, 2);
      expect(repository.readMessageIds, [_message1]);
      expect(changes, 0);

      reload.complete(
        ChatMessagePage(messages: [_message(id: _message1, minute: 1)]),
      );
      await _pump();
      expect(repository.readMessageIds, [_message1, _message1]);
      retry.complete();
      await _pump();

      expect(repository.messageLoadCount, 2);
      expect(repository.readMessageIds, [_message1, _message1]);
      expect(changes, 1);
      await cubit.close();
    });

    test('conflict followed by backwards retry notifies once', () async {
      var changes = 0;
      final firstRead = Completer<void>();
      final reload = Completer<ChatMessagePage>();
      final retry = Completer<void>();
      final repository = _FakeChatRepository()
        ..messageLoads.add(
          ChatMessagePage(messages: [_message(id: _message1, minute: 1)]),
        )
        ..messageLoads.add(reload.future)
        ..readResults.add(firstRead.future)
        ..readResults.add(retry.future);
      final cubit = ChatConversationCubit(
        repository,
        _FakeRealtime(),
        onChanged: () => changes++,
      )..bind(_scope, _group);
      await _pump();

      firstRead.completeError(_readConflict());
      await _pump();
      reload.complete(
        ChatMessagePage(messages: [_message(id: _message1, minute: 1)]),
      );
      await _pump();
      retry.completeError(
        const ApiException(
          message: 'safe',
          code: 'CHAT_READ_POSITION_BACKWARDS',
        ),
      );
      await _pump();

      expect(repository.messageLoadCount, 2);
      expect(repository.readMessageIds, [_message1, _message1]);
      expect(changes, 1);
      await cubit.close();
    });

    test('repeated conflict is bounded and remains retryable', () async {
      var changes = 0;
      final firstRead = Completer<void>();
      final reload = Completer<ChatMessagePage>();
      final retry = Completer<void>();
      final repository = _FakeChatRepository()
        ..messageLoads.add(
          ChatMessagePage(messages: [_message(id: _message1, minute: 1)]),
        )
        ..messageLoads.add(reload.future)
        ..readResults.add(firstRead.future)
        ..readResults.add(retry.future);
      final cubit = ChatConversationCubit(
        repository,
        _FakeRealtime(),
        onChanged: () => changes++,
      )..bind(_scope, _group);
      await _pump();

      firstRead.completeError(_readConflict());
      await _pump();
      reload.complete(
        ChatMessagePage(messages: [_message(id: _message1, minute: 1)]),
      );
      await _pump();
      retry.completeError(_readConflict());
      await _pump();

      expect(repository.messageLoadCount, 2);
      expect(repository.readMessageIds, [_message1, _message1]);
      expect(changes, 0);

      repository.messageLoads.add(
        ChatMessagePage(messages: [_message(id: _message1, minute: 1)]),
      );
      repository.readResults.add(Future.value());
      await cubit.load(refresh: true);
      await _pump();
      expect(repository.readMessageIds, [_message1, _message1, _message1]);
      expect(changes, 1);
      await cubit.close();
    });

    test('conflict retry failures never refresh shared group state', () async {
      final errors = <Object>[
        Exception('network'),
        const ApiException(message: 'timeout', kind: FailureKind.timeout),
        DioException(
          requestOptions: RequestOptions(path: '/chat/read'),
          type: DioExceptionType.cancel,
        ),
        const ApiException(message: 'rate limited', statusCode: 429),
        const ApiException(message: 'server', statusCode: 500),
        const ApiException(message: 'gateway', statusCode: 502),
      ];
      for (final error in errors) {
        var changes = 0;
        final firstRead = Completer<void>();
        final reload = Completer<ChatMessagePage>();
        final retry = Completer<void>();
        final repository = _FakeChatRepository()
          ..messageLoads.add(
            ChatMessagePage(messages: [_message(id: _message1, minute: 1)]),
          )
          ..messageLoads.add(reload.future)
          ..readResults.add(firstRead.future)
          ..readResults.add(retry.future);
        final cubit = ChatConversationCubit(
          repository,
          _FakeRealtime(),
          onChanged: () => changes++,
        )..bind(_scope, _group);
        await _pump();

        firstRead.completeError(_readConflict());
        await _pump();
        reload.complete(
          ChatMessagePage(messages: [_message(id: _message1, minute: 1)]),
        );
        await _pump();
        retry.completeError(error);
        await _pump();

        expect(repository.messageLoadCount, 2, reason: '$error');
        expect(repository.readMessageIds, [
          _message1,
          _message1,
        ], reason: '$error');
        expect(changes, 0, reason: '$error');
        await cubit.close();
      }
    });

    test('general mark-read failures never refresh the group list', () async {
      final errors = <Object>[
        Exception('network'),
        const ApiException(message: 'timeout', kind: FailureKind.timeout),
        DioException(
          requestOptions: RequestOptions(path: '/chat/read'),
          type: DioExceptionType.cancel,
        ),
        const ApiException(message: 'rate limited', statusCode: 429),
        const ApiException(message: 'server', statusCode: 500),
        const ApiException(message: 'gateway', statusCode: 502),
      ];
      for (final error in errors) {
        var changes = 0;
        final repository = _FakeChatRepository()
          ..messageLoads.add(
            ChatMessagePage(messages: [_message(id: _message1, minute: 1)]),
          )
          ..readResults.add(
            Future<void>.delayed(Duration.zero, () => throw error),
          );
        final cubit = ChatConversationCubit(
          repository,
          _FakeRealtime(),
          onChanged: () => changes++,
        )..bind(_scope, _group);
        await _pump();
        expect(changes, 0, reason: '$error');
        await cubit.close();
      }
    });

    test('session changes and close invalidate old read completions', () async {
      var changes = 0;
      final read = Completer<void>();
      final repository = _FakeChatRepository()
        ..messageLoads.add(
          ChatMessagePage(messages: [_message(id: _message1, minute: 1)]),
        )
        ..readResults.add(read.future);
      final realtime = _FakeRealtime();
      final cubit = ChatConversationCubit(
        repository,
        realtime,
        onChanged: () => changes++,
      )..bind(_scope, _group);
      await _pump();
      cubit.bind(
        const FeatureSessionScope(
          userId: '77777777-7777-4777-8777-777777777777',
          workspaceId: _otherWorkspace,
          membershipId: _membership,
          timezone: 'Etc/UTC',
          role: WorkspaceRole.manager,
        ),
        _group,
      );
      await _pump();
      read.complete();
      realtime.insert();
      await cubit.close();
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(changes, 0);
      expect(repository.messageLoadCount, 2);
    });

    test('scope change invalidates an in-progress conflict reload', () async {
      var changes = 0;
      final firstRead = Completer<void>();
      final oldReload = Completer<ChatMessagePage>();
      final repository = _FakeChatRepository()
        ..messageLoads.add(
          ChatMessagePage(messages: [_message(id: _message1, minute: 1)]),
        )
        ..messageLoads.add(oldReload.future)
        ..messageLoads.add(const ChatMessagePage(messages: []))
        ..readResults.add(firstRead.future);
      final cubit = ChatConversationCubit(
        repository,
        _FakeRealtime(),
        onChanged: () => changes++,
      )..bind(_scope, _group);
      await _pump();
      firstRead.completeError(_readConflict());
      await _pump();
      expect(repository.messageLoadCount, 2);

      cubit.bind(
        const FeatureSessionScope(
          userId: '77777777-7777-4777-8777-777777777777',
          workspaceId: _otherWorkspace,
          membershipId: _membership,
          timezone: 'Etc/UTC',
          role: WorkspaceRole.employee,
        ),
        _group,
      );
      await _pump();
      oldReload.complete(
        ChatMessagePage(messages: [_message(id: _message2, minute: 2)]),
      );
      await _pump();

      expect(repository.messageLoadCount, 3);
      expect(repository.readMessageIds, [_message1]);
      expect(cubit.state.messages, isEmpty);
      expect(changes, 0);
      await cubit.close();
    });

    test('close invalidates an in-progress conflict reload', () async {
      var changes = 0;
      final firstRead = Completer<void>();
      final reload = Completer<ChatMessagePage>();
      final repository = _FakeChatRepository()
        ..messageLoads.add(
          ChatMessagePage(messages: [_message(id: _message1, minute: 1)]),
        )
        ..messageLoads.add(reload.future)
        ..readResults.add(firstRead.future);
      final cubit = ChatConversationCubit(
        repository,
        _FakeRealtime(),
        onChanged: () => changes++,
      )..bind(_scope, _group);
      await _pump();
      firstRead.completeError(_readConflict());
      await _pump();
      expect(repository.messageLoadCount, 2);

      await cubit.close();
      reload.complete(
        ChatMessagePage(messages: [_message(id: _message2, minute: 2)]),
      );
      await _pump();

      expect(repository.readMessageIds, [_message1]);
      expect(changes, 0);
    });
  });

  group('single-flight unread refresh', () {
    test('initial load failure preserves a newer unread refresh', () async {
      final groups = Completer<List<ChatGroup>>();
      final fullUnread = Completer<int>();
      final repository = _FakeChatRepository()
        ..groupLoads.add(groups.future)
        ..unreadLoads.add(fullUnread.future);
      final cubit = ChatGroupsCubit(repository)..bindSession(_scope);
      await _pump();

      repository.unreadLoads.add(Future.value(9));
      await cubit.refreshUnread();
      expect(cubit.state.unreadCount, 9);

      groups.completeError(Exception('offline'));
      fullUnread.complete(1);
      await _pump();

      expect(cubit.state.loading, isFalse);
      expect(cubit.state.groups, isEmpty);
      expect(cubit.state.unreadCount, 9);
      expect(cubit.state.failure?.message, 'Unable to load chat groups.');
      await cubit.close();
    });

    test('retained-data failure preserves groups and newer unread', () async {
      final existing = _chatGroup(memberCount: 4);
      final repository = _FakeChatRepository()
        ..groupLoads.add(Future.value([existing]))
        ..unreadLoads.add(Future.value(3));
      final cubit = ChatGroupsCubit(repository)..bindSession(_scope);
      await _pump();

      final groups = Completer<List<ChatGroup>>();
      final fullUnread = Completer<int>();
      repository.groupLoads.add(groups.future);
      repository.unreadLoads
        ..add(fullUnread.future)
        ..add(Future.value(11));
      final refresh = cubit.load(refresh: true);
      await _pump();
      await cubit.refreshUnread();
      expect(cubit.state.unreadCount, 11);

      groups.completeError(Exception('offline'));
      fullUnread.complete(2);
      await refresh;

      expect(cubit.state.groups, [existing]);
      expect(cubit.state.unreadCount, 11);
      expect(cubit.state.refreshing, isFalse);
      expect(cubit.state.failure?.message, 'Unable to load chat groups.');
      await cubit.close();
    });

    test('old load failure cannot update a new session', () async {
      final oldGroups = Completer<List<ChatGroup>>();
      final oldFullUnread = Completer<int>();
      final repository = _FakeChatRepository()
        ..groupLoads.add(oldGroups.future)
        ..groupLoads.add(Future.value(const []))
        ..unreadLoads.add(oldFullUnread.future)
        ..unreadLoads.add(Future.value(6))
        ..unreadLoads.add(Future.value(12));
      final cubit = ChatGroupsCubit(repository)..bindSession(_scope);
      await _pump();
      await cubit.refreshUnread();
      expect(cubit.state.unreadCount, 6);

      cubit.bindSession(
        const FeatureSessionScope(
          userId: '77777777-7777-4777-8777-777777777777',
          workspaceId: _otherWorkspace,
          membershipId: _membership,
          timezone: 'Etc/UTC',
          role: WorkspaceRole.employee,
        ),
      );
      await _pump();
      expect(cubit.state.unreadCount, 12);

      oldGroups.completeError(Exception('offline'));
      oldFullUnread.complete(1);
      await _pump();

      expect(cubit.scope?.workspaceId, _otherWorkspace);
      expect(cubit.state.groups, isEmpty);
      expect(cubit.state.unreadCount, 12);
      expect(cubit.state.failure, isNull);
      await cubit.close();
    });

    test('close rejects a late full-load failure', () async {
      final groups = Completer<List<ChatGroup>>();
      final fullUnread = Completer<int>();
      final repository = _FakeChatRepository()
        ..groupLoads.add(groups.future)
        ..unreadLoads.add(fullUnread.future);
      final cubit = ChatGroupsCubit(repository)..bindSession(_scope);
      await _pump();
      final beforeClose = cubit.state;
      await cubit.close();

      groups.completeError(Exception('offline'));
      fullUnread.complete(99);
      await _pump();

      expect(cubit.state, beforeClose);
    });

    test('newer unread-only result survives an older full load', () async {
      final groups = Completer<List<ChatGroup>>();
      final fullUnread = Completer<int>();
      final repository = _FakeChatRepository()
        ..unreadLoads.add(Future.value(7));
      final cubit = ChatGroupsCubit(repository)..bindSession(_scope);
      await _pump();

      repository.groupLoads.add(groups.future);
      repository.unreadLoads
        ..add(fullUnread.future)
        ..add(Future.value(2));
      final load = cubit.load(refresh: true);
      await _pump();
      await cubit.refreshUnread();
      expect(cubit.state.unreadCount, 2);

      groups.complete([_chatGroup(memberCount: 8)]);
      fullUnread.complete(5);
      await load;
      expect(cubit.state.groups.single.memberCount, 8);
      expect(cubit.state.unreadCount, 2);
      await cubit.close();
    });

    test(
      'newer full-load result survives an older unread-only result',
      () async {
        final unreadOnly = Completer<int>();
        final repository = _FakeChatRepository()
          ..unreadLoads.add(Future.value(1));
        final cubit = ChatGroupsCubit(repository)..bindSession(_scope);
        await _pump();

        repository.unreadLoads.add(unreadOnly.future);
        final unread = cubit.refreshUnread();
        await _pump();
        repository.groupLoads.add(Future.value([_chatGroup(memberCount: 6)]));
        repository.unreadLoads.add(Future.value(3));
        await cubit.load(refresh: true);
        expect(cubit.state.unreadCount, 3);
        unreadOnly.complete(9);
        await unread;
        expect(cubit.state.groups.single.memberCount, 6);
        expect(cubit.state.unreadCount, 3);
        await cubit.close();
      },
    );

    test(
      'mutation groups apply without overwriting newer unread result',
      () async {
        final mutationGroups = Completer<List<ChatGroup>>();
        final mutationUnread = Completer<int>();
        final repository = _FakeChatRepository()
          ..groupLoads.add(Future.value([_chatGroup()]))
          ..unreadLoads.add(Future.value(4));
        final cubit = ChatGroupsCubit(repository)..bindSession(_scope);
        await _pump();

        repository.groupLoads.add(mutationGroups.future);
        repository.unreadLoads
          ..add(mutationUnread.future)
          ..add(Future.value(1));
        final mutation = cubit.archive(_group);
        await _pump();
        await cubit.refreshUnread();
        mutationGroups.complete([_chatGroup(memberCount: 11)]);
        mutationUnread.complete(6);
        expect(await mutation, ChatMutationResult.success);
        expect(cubit.state.groups.single.memberCount, 11);
        expect(cubit.state.unreadCount, 1);
        await cubit.close();
      },
    );

    test('newer unread failure does not suppress an older success', () async {
      final groups = Completer<List<ChatGroup>>();
      final olderUnread = Completer<int>();
      final repository = _FakeChatRepository()
        ..unreadLoads.add(Future.value(8));
      final cubit = ChatGroupsCubit(repository)..bindSession(_scope);
      await _pump();

      repository.groupLoads.add(groups.future);
      repository.unreadLoads.add(olderUnread.future);
      final load = cubit.load(refresh: true);
      repository.unreadLoads.add(
        Future<int>.delayed(Duration.zero, () => throw Exception('offline')),
      );
      await cubit.refreshUnread();
      expect(cubit.state.unreadCount, 8);
      groups.complete([_chatGroup(memberCount: 3)]);
      olderUnread.complete(4);
      await load;
      expect(cubit.state.groups.single.memberCount, 3);
      expect(cubit.state.unreadCount, 4);
      await cubit.close();
    });

    test(
      'coalesces repeated triggers and applies the follow-up response',
      () async {
        final active = Completer<int>();
        final repository = _FakeChatRepository()
          ..unreadLoads.add(Future.value(1));
        final cubit = ChatGroupsCubit(repository)..bindSession(_scope);
        await _pump();
        repository.unreadLoads
          ..add(active.future)
          ..add(Future.value(9));
        final first = cubit.refreshUnread();
        await cubit.refreshUnread();
        await cubit.refreshUnread();
        expect(repository.unreadLoadCount, 2);
        active.complete(4);
        await first;
        await _pump();
        expect(repository.unreadLoadCount, 3);
        expect(cubit.state.unreadCount, 9);
        await cubit.close();
      },
    );

    test(
      'failure retains the badge and old-session completion is ignored',
      () async {
        final old = Completer<int>();
        final repository = _FakeChatRepository()
          ..unreadLoads.add(Future.value(5));
        final cubit = ChatGroupsCubit(repository)..bindSession(_scope);
        await _pump();
        repository.unreadLoads.add(Future<int>.error(Exception('offline')));
        await cubit.refreshUnread();
        expect(cubit.state.unreadCount, 5);

        repository.unreadLoads
          ..add(old.future)
          ..add(Future.value(8));
        unawaited(cubit.refreshUnread());
        await _pump();
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
        old.complete(99);
        await _pump();
        expect(cubit.state.unreadCount, 8);
        await cubit.close();
      },
    );

    test('close prevents a late unread update', () async {
      final late = Completer<int>();
      final repository = _FakeChatRepository()
        ..unreadLoads.add(Future.value(2));
      final cubit = ChatGroupsCubit(repository)..bindSession(_scope);
      await _pump();
      repository.unreadLoads.add(late.future);
      unawaited(cubit.refreshUnread());
      await _pump();
      await cubit.close();
      late.complete(50);
      await _pump();
      expect(cubit.state.unreadCount, 2);
    });

    test(
      'full load cannot clear unread single-flight or its queued run',
      () async {
        final activeUnread = Completer<int>();
        final repository = _FakeChatRepository()
          ..unreadLoads.add(Future.value(1));
        final cubit = ChatGroupsCubit(repository)..bindSession(_scope);
        await _pump();

        repository.unreadLoads
          ..add(activeUnread.future)
          ..add(Future.value(7))
          ..add(Future.value(9));
        final active = cubit.refreshUnread();
        await cubit.refreshUnread();
        repository.groupLoads.add(Future.value([_chatGroup(memberCount: 5)]));
        await cubit.load(refresh: true);
        expect(cubit.state.unreadCount, 7);
        activeUnread.complete(3);
        await active;
        await _pump();
        expect(repository.unreadLoadCount, 4);
        expect(cubit.state.unreadCount, 9);
        await cubit.close();
      },
    );

    test(
      'session change rejects old full, unread, and mutation results',
      () async {
        final oldGroups = Completer<List<ChatGroup>>();
        final oldUnread = Completer<int>();
        final repository = _FakeChatRepository()
          ..groupLoads.add(Future.value([_chatGroup()]))
          ..unreadLoads.add(Future.value(1));
        final cubit = ChatGroupsCubit(repository)..bindSession(_scope);
        await _pump();

        repository.groupLoads
          ..add(oldGroups.future)
          ..add(Future.value(const []));
        repository.unreadLoads
          ..add(oldUnread.future)
          ..add(Future.value(8));
        final mutation = cubit.archive(_group);
        await _pump();
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
        oldGroups.complete([_chatGroup(memberCount: 99)]);
        oldUnread.complete(99);
        expect(await mutation, ChatMutationResult.stale);
        await _pump();
        expect(cubit.state.groups, isEmpty);
        expect(cubit.state.unreadCount, 8);
        await cubit.close();
      },
    );

    test('close rejects late full-load and unread-only completions', () async {
      final groups = Completer<List<ChatGroup>>();
      final fullUnread = Completer<int>();
      final unreadOnly = Completer<int>();
      final repository = _FakeChatRepository()
        ..unreadLoads.add(Future.value(2));
      final cubit = ChatGroupsCubit(repository)..bindSession(_scope);
      await _pump();
      repository.groupLoads.add(groups.future);
      repository.unreadLoads
        ..add(fullUnread.future)
        ..add(unreadOnly.future);
      final load = cubit.load(refresh: true);
      final unread = cubit.refreshUnread();
      await _pump();
      await cubit.close();
      groups.complete([_chatGroup(memberCount: 100)]);
      fullUnread.complete(100);
      unreadOnly.complete(100);
      await Future.wait([load, unread]);
      expect(cubit.state.unreadCount, 2);
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

    testWidgets('create dialog tracks pending, failure, and success', (
      tester,
    ) async {
      final failure = Completer<ChatGroup>();
      final repository = _FakeChatRepository()..createResult = failure.future;
      final cubit = ChatGroupsCubit(repository)..bindSession(_scope);
      await tester.pumpWidget(
        RepositoryProvider<EmployeeRepository>.value(
          value: _FakeEmployeeRepository([_employee()]),
          child: BlocProvider.value(
            value: cubit,
            child: const MaterialApp(home: ChatGroupsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('create-chat-group')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('create-group-name')),
        'Night Operations',
      );
      await tester.enterText(
        find.byKey(const Key('create-group-description')),
        'Coverage team',
      );
      await tester.tap(find.byKey(const Key('create-group-member-$_message2')));
      await tester.tap(find.byKey(const Key('create-group-submit')));
      await tester.pump();

      expect(repository.createCalls, 1);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('create-group-name')))
            .enabled,
        isFalse,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const Key('create-group-member-$_message2')),
            )
            .onChanged,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('create-group-cancel')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('create-group-submit')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const Key('create-group-submit')));
      await tester.pump();
      expect(repository.createCalls, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      failure.completeError(Exception('offline'));
      await tester.pumpAndSettle();
      expect(find.text('Create chat group'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('create-group-name')))
            .controller!
            .text,
        'Night Operations',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('create-group-name')))
            .enabled,
        isTrue,
      );

      final success = Completer<ChatGroup>();
      repository.createResult = success.future;
      await tester.tap(find.byKey(const Key('create-group-submit')));
      await tester.pump();
      expect(repository.createCalls, 2);
      success.complete(_chatGroup());
      await tester.pumpAndSettle();
      expect(find.text('Create chat group'), findsNothing);
      await cubit.close();
    });

    testWidgets('edit dialog reacts to mutation and rejects stale scope', (
      tester,
    ) async {
      final update = Completer<void>();
      final repository = _FakeChatRepository()
        ..groupLoads.add(Future.value([_chatGroup()]))
        ..updateResult = update.future;
      final groups = ChatGroupsCubit(repository)..bindSession(_scope);
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<ChatRepository>.value(value: repository),
            RepositoryProvider<ChatRealtime>.value(value: _FakeRealtime()),
            RepositoryProvider<EmployeeRepository>.value(
              value: _FakeEmployeeRepository(),
            ),
          ],
          child: BlocProvider.value(
            value: groups,
            child: const MaterialApp(home: ChatScreen(groupId: _group)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit group'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('edit-group-name')),
        'Updated Operations',
      );
      await tester.enterText(
        find.byKey(const Key('edit-group-description')),
        'Updated description',
      );
      await tester.tap(find.byKey(const Key('edit-group-submit')));
      await tester.pump();

      expect(repository.updateCalls, 1);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('edit-group-name')))
            .enabled,
        isFalse,
      );
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('edit-group-cancel')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('edit-group-submit')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const Key('edit-group-submit')));
      await tester.pump();
      expect(repository.updateCalls, 1);

      groups.bindSession(
        const FeatureSessionScope(
          userId: '77777777-7777-4777-8777-777777777777',
          workspaceId: _otherWorkspace,
          membershipId: _membership,
          timezone: 'Etc/UTC',
          role: WorkspaceRole.manager,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Edit group'), findsNothing);
      update.complete();
      await tester.pump();
      expect(repository.updateCalls, 1);
      await groups.close();
    });

    testWidgets('edit failure preserves values and success closes', (
      tester,
    ) async {
      final failure = Completer<void>();
      final repository = _FakeChatRepository()
        ..groupLoads.add(Future.value([_chatGroup()]))
        ..updateResult = failure.future;
      final groups = ChatGroupsCubit(repository)..bindSession(_scope);
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<ChatRepository>.value(value: repository),
            RepositoryProvider<ChatRealtime>.value(value: _FakeRealtime()),
            RepositoryProvider<EmployeeRepository>.value(
              value: _FakeEmployeeRepository(),
            ),
          ],
          child: BlocProvider.value(
            value: groups,
            child: const MaterialApp(home: ChatScreen(groupId: _group)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit group'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('edit-group-name')),
        'Preserved name',
      );
      await tester.enterText(
        find.byKey(const Key('edit-group-description')),
        'Preserved description',
      );
      await tester.tap(find.byKey(const Key('edit-group-submit')));
      await tester.pump();
      failure.completeError(Exception('offline'));
      await tester.pumpAndSettle();

      expect(find.text('Edit group'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('edit-group-name')))
            .controller!
            .text,
        'Preserved name',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('edit-group-description')))
            .enabled,
        isTrue,
      );

      final success = Completer<void>();
      repository.updateResult = success.future;
      await tester.tap(find.byKey(const Key('edit-group-submit')));
      await tester.pump();
      expect(repository.updateCalls, 2);
      success.complete();
      await tester.pumpAndSettle();
      expect(find.text('Edit group'), findsNothing);
      await groups.close();
    });
  });
}

ApiException _readConflict() =>
    const ApiException(message: 'sync', code: 'CHAT_READ_POSITION_CONFLICT');

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

ChatMessage _messageAt(String id, DateTime createdAt) => ChatMessage.fromJson({
  ..._messageJson(id: id),
  'createdAt': createdAt.toIso8601String(),
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

Employee _employee() => const Employee(
  id: _message2,
  fullName: 'Taylor',
  phone: null,
  email: 'taylor@example.com',
  jobTitle: null,
  location: null,
  shift: null,
  startDate: null,
  employmentStatus: EmploymentStatus.active,
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

class _FakeChatRepository extends ChatRepository {
  final groupLoads = <Future<List<ChatGroup>>>[];
  final messageLoads = <Object>[];
  final unreadLoads = <Future<int>>[];
  final readResults = <Future<void>>[];
  final readMessageIds = <String>[];
  final sentTexts = <String>[];
  final clientIds = <String>[];
  int sendFailures = 0;
  int messageLoadCount = 0;
  int memberMutations = 0;
  int unreadLoadCount = 0;
  int createCalls = 0;
  int updateCalls = 0;
  ChatGroup details = _chatGroup();
  Future<ChatGroup>? createResult;
  Future<void>? updateResult;

  @override
  Future<List<ChatGroup>> listGroups(String workspaceId) =>
      groupLoads.isEmpty ? Future.value(const []) : groupLoads.removeAt(0);
  @override
  Future<int> unreadCount(String workspaceId) {
    unreadLoadCount++;
    return unreadLoads.isEmpty ? Future.value(0) : unreadLoads.removeAt(0);
  }

  @override
  Future<ChatMessagePage> listMessages(
    String workspaceId,
    String groupId, {
    String? cursor,
    int limit = 30,
  }) async {
    messageLoadCount++;
    if (messageLoads.isEmpty) return const ChatMessagePage(messages: []);
    final value = messageLoads.removeAt(0);
    return value is Future<ChatMessagePage>
        ? await value
        : value as ChatMessagePage;
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
  Future<void> markRead(String workspaceId, String groupId, String messageId) {
    readMessageIds.add(messageId);
    return readResults.isEmpty ? Future.value() : readResults.removeAt(0);
  }

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
  }) {
    createCalls++;
    return createResult ?? Future.value(details);
  }

  @override
  Future<void> updateGroup(
    String workspaceId,
    String groupId, {
    required String name,
    String? description,
  }) {
    updateCalls++;
    return updateResult ?? Future.value();
  }
}

class _FakeEmployeeRepository implements EmployeeRepository {
  _FakeEmployeeRepository([this.employees = const []]);
  final List<Employee> employees;

  @override
  Future<EmployeePage> listEmployees({
    required String workspaceId,
    String search = '',
    EmployeeStatusFilter? status,
    int page = 1,
    int limit = 20,
  }) async => EmployeePage(
    data: employees,
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
