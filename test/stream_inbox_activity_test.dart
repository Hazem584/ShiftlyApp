import 'dart:async';

import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:shiftly/features/chat/data/mock_chat_repository.dart';
import 'package:shiftly/features/chat/data/stream/stream_chat_realtime.dart';
import 'package:shiftly/features/chat/data/stream/stream_chat_repository.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as sdk;

import 'stream_chat_transport_test.dart'
    show
        TestChannel,
        TestChannelState,
        TestConnection,
        TestLegacyRealtime,
        group,
        member,
        message,
        messageId,
        session,
        workspace;

void main() {
  testWidgets(
    'confirmed read clears both badges before an old reload finishes',
    (tester) async {
      final fixture = _InboxFixture();
      addTearDown(fixture.close);
      await tester.pump();
      expect(fixture.cubit.state.groups.single.unreadCount, 2);
      expect(fixture.cubit.state.unreadCount, 2);

      final old = Completer<void>();
      fixture.connection.nextChannels = old.future;
      unawaited(fixture.cubit.load(refresh: true));
      await tester.pump();

      await fixture.repository.markRead(workspace, group, messageId(1));
      expect(fixture.connection.current.readIds, [messageId(1)]);
      expect(fixture.cubit.state.groups.single.unreadCount, 0);
      expect(fixture.cubit.state.unreadCount, 0);

      old.complete();
      await tester.pump();
      expect(fixture.cubit.state.groups.single.unreadCount, 0);
      expect(fixture.cubit.state.unreadCount, 0);
      await fixture.close();
    },
  );

  testWidgets('send acknowledgement updates preview before refreshing groups', (
    tester,
  ) async {
    final fixture = _InboxFixture();
    addTearDown(fixture.close);
    await tester.pump();

    final result = await fixture.repository.sendMessage(
      workspace,
      group,
      text: 'Preview outside the chat',
      clientMessageId: messageId(2),
    );
    expect(fixture.cubit.state.groups.single.lastMessage, result);
    expect(fixture.cubit.state.groups.single.unreadCount, 2);
    await fixture.close();
  });

  testWidgets('incoming new message updates the inbox without a reload', (
    tester,
  ) async {
    final fixture = _InboxFixture();
    addTearDown(fixture.close);
    await tester.pump();
    final incoming = message(2).copyWith(user: sdk.User(id: messageId(8)));
    final event = sdk.Event(
      type: sdk.EventType.notificationMessageNew,
      cid: 'shiftly:$group',
      message: incoming,
    );
    fixture.connection.incoming.add(event);
    fixture.connection.incoming.add(event);
    await tester.pump();

    expect(fixture.cubit.state.groups.single.lastMessage?.id, incoming.id);
    expect(fixture.cubit.state.groups.single.unreadCount, 3);
    expect(fixture.cubit.state.unreadCount, 3);
    await fixture.close();
  });

  testWidgets('reading a previous message leaves a newer message unread', (
    tester,
  ) async {
    final fixture = _InboxFixture();
    addTearDown(fixture.close);
    await tester.pump();

    fixture.connection.incoming.add(
      sdk.Event(
        type: sdk.EventType.messageNew,
        cid: 'shiftly:$group',
        message: message(2).copyWith(user: sdk.User(id: messageId(8))),
      ),
    );
    await tester.pump();
    await fixture.repository.markRead(workspace, group, messageId(1));

    expect(fixture.cubit.state.groups.single.unreadCount, 3);
    await fixture.close();
  });
}

class _InboxFixture {
  _InboxFixture() {
    repository = StreamChatRepository(legacy, connection);
    cubit = ChatGroupsCubit(
      repository,
      realtime: StreamChatRealtime(connection, TestLegacyRealtime()),
    )..bindSession(session);
  }

  final legacy = _Legacy();
  final connection = _Connection();
  late final StreamChatRepository repository;
  late final ChatGroupsCubit cubit;

  Future<void> close() async {
    if (cubit.isClosed) return;
    await cubit.close();
    await connection.dispose();
  }
}

class _Legacy extends MockChatRepository {
  @override
  Future<List<ChatGroup>> listGroups(String workspaceId) async => [snapshot()];

  ChatGroup snapshot() => ChatGroup(
    id: group,
    workspaceId: workspace,
    name: 'Team',
    memberCount: 2,
    unreadCount: 0,
    createdAt: DateTime.utc(2025),
    updatedAt: DateTime.utc(2025),
  );
}

class _Connection extends TestConnection {
  _Connection() {
    testClient.unread = [
      sdk.UnreadCountsChannel(
        channelId: 'shiftly:$group',
        unreadCount: 2,
        lastRead: DateTime.utc(2025),
      ),
    ];
  }

  late final current = _Channel(() => testClient.unread = []);
  Future<void>? nextChannels;
  @override
  Future<sdk.Channel> channel(String workspaceId, String groupId) async =>
      current;
  @override
  Future<Map<String, sdk.Channel>> channels(
    String workspaceId,
    Set<String> allowed,
  ) async {
    final pending = nextChannels;
    nextChannels = null;
    if (pending != null) await pending;
    return {for (final id in allowed) id: current};
  }
}

class _Channel extends TestChannel {
  _Channel(this.onRead);
  final void Function() onRead;
  final readIds = <String?>[];
  @override
  sdk.ChannelClientState get state => _State();
  @override
  Future<sdk.EmptyResponse> markRead({String? messageId}) async {
    readIds.add(messageId);
    onRead();
    return sdk.EmptyResponse();
  }
}

class _State extends TestChannelState {
  @override
  List<sdk.Message> get messages => [
    message(1).copyWith(
      user: sdk.User(id: member),
      createdAt: DateTime.utc(2026, 11, 13),
    ),
  ];
}
