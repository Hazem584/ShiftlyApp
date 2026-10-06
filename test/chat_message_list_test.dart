import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/features/chat/data/chat_models.dart';
import 'package:shiftly/features/chat/presentation/widgets/messages/shiftly_chat_message_list.dart';

ChatMessage _message(int index, {bool mine = false}) => ChatMessage(
  id: index.toString().padLeft(36, '0'),
  groupId: '00000000-0000-4000-8000-000000000001',
  type: 'TEXT',
  text: index == 4
      ? 'A-very-long-unbroken-message-that-must-wrap-safely-without-overflowing-the-mobile-viewport-$index'
      : 'Message $index',
  sender: ChatSender(
    membershipId: mine ? 'mine' : 'other',
    fullName: mine ? 'Me' : 'A very long translated sender name',
  ),
  createdAt: DateTime.utc(2026, 10, 6, 10, index),
);

Widget _app(
  List<ChatMessage> messages, {
  bool hasMore = false,
  Future<void> Function()? onLoadOlder,
}) => MaterialApp(
  home: MediaQuery(
    data: const MediaQueryData(
      size: Size(320, 700),
      textScaler: TextScaler.linear(1.3),
    ),
    child: Scaffold(
      body: ShiftlyChatMessageList(
        messages: messages,
        currentMembershipId: 'mine',
        loading: false,
        failureMessage: null,
        hasMore: hasMore,
        loadingOlder: false,
        onLoadOlder: onLoadOlder ?? () async {},
        onRetry: () {},
        messageBuilder: (message, mine, _) => Align(
          key: Key('message-${message.id}'),
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 240),
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.all(8),
            child: Text(message.text!),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('chronological list opens at newest without compact overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final messages = [for (var i = 0; i < 12; i++) _message(i, mine: i.isOdd)];
    await tester.pumpWidget(_app(messages));
    await tester.pumpAndSettle();
    expect(find.text('Message 11'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'new remote message preserves reading position and indicator works',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final messages = [for (var i = 0; i < 18; i++) _message(i)];
      await tester.pumpWidget(_app(messages));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const Key('chat-message-list')),
        const Offset(0, 500),
      );
      await tester.pump();
      await tester.pumpWidget(_app([...messages, _message(18)]));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-new-messages')), findsOneWidget);
      await tester.tap(find.byKey(const Key('chat-new-messages')));
      await tester.pumpAndSettle();
      expect(find.text('Message 18'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('older pagination preserves the visible message anchor', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final requested = Completer<void>();
    final release = Completer<void>();
    var hasMore = true;
    var messages = [for (var i = 20; i < 40; i++) _message(i)];
    late StateSetter update;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 700),
            textScaler: TextScaler.linear(1.3),
          ),
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return ShiftlyChatMessageList(
                  messages: messages,
                  currentMembershipId: 'mine',
                  loading: false,
                  failureMessage: null,
                  hasMore: hasMore,
                  loadingOlder: false,
                  onLoadOlder: () async {
                    if (!requested.isCompleted) requested.complete();
                    await release.future;
                    update(() {
                      messages = [
                        for (var i = 0; i < 20; i++) _message(i),
                        ...messages,
                      ];
                      hasMore = false;
                    });
                  },
                  onRetry: () {},
                  messageBuilder: (message, mine, _) => Align(
                    key: Key('message-${message.id}'),
                    alignment: mine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 240),
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.all(8),
                      child: Text(message.text!),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('chat-message-list')),
      const Offset(0, 5000),
    );
    await tester.pump();
    await requested.future;
    Finder? anchor;
    for (final message in messages) {
      final candidate = find.byKey(
        Key('chat-message-${message.id}'),
        skipOffstage: false,
      );
      if (candidate.evaluate().isEmpty) continue;
      final bounds = tester.getRect(candidate);
      if (bounds.bottom > 0 && bounds.top < 700) {
        anchor = candidate;
        break;
      }
    }
    expect(anchor, isNotNull);
    final before = tester.getTopLeft(anchor!).dy;
    release.complete();
    await tester.pumpAndSettle();
    debugPrint(messages.where((message) => find.text(message.text!, skipOffstage: false).evaluate().isNotEmpty).map((message) => message.text).join(', '));
    final after = tester.getTopLeft(anchor).dy;

    expect(after, closeTo(before, 1));
    expect(tester.takeException(), isNull);
  });
}
