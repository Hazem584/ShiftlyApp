import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/features/chat/data/mock_chat_repository.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/services/chat_message_summary.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_group_tile.dart';

ChatMessage message({
  String? text,
  String type = 'TEXT',
  DateTime? deletedAt,
}) => ChatMessage(
  id: 'message',
  groupId: 'group',
  type: type,
  text: text,
  sender: const ChatSender(membershipId: 'sender', fullName: 'Hazem'),
  createdAt: DateTime.utc(2026, 11, 20, 10, 15),
  deletedAt: deletedAt,
);
void main() {
  test('summary preserves message text without translating user content', () {
    expect(chatMessageSummary(message(text: 'Hello team')).text, 'Hello team');
  });
  for (final item in {
    'IMAGE': 'Photo',
    'VOICE': 'Voice message',
    'DOCUMENT': 'Document',
    'LOCATION': 'Location',
  }.entries) {
    test('${item.key} with empty Stream text has a readable summary', () {
      final summary = chatMessageSummary(message(type: item.key, text: '  '));
      expect(summary.text, isNull);
      expect(summary.label, item.value);
    });
  }
  test('deleted message never exposes its previous text', () {
    expect(
      chatMessageSummary(
        message(text: 'removed', deletedAt: DateTime.utc(2026)),
      ).label,
      'Message deleted',
    );
  });
  test('empty group explicitly displays no messages', () {
    expect(chatMessageSummary(null).label, 'No messages yet');
  });
  for (final type in ['TEXT', 'IMAGE', 'VOICE', 'DOCUMENT', 'LOCATION']) {
    testWidgets('group tile renders $type preview beside the member count', (
      tester,
    ) async {
      final cubit = ChatGroupsCubit(const MockChatRepository());
      addTearDown(cubit.close);
      final msg = message(text: type == 'TEXT' ? 'Hello team' : '', type: type);
      final group = ChatGroup(
        id: 'group',
        workspaceId: 'workspace',
        name: 'Instock',
        memberCount: 2,
        unreadCount: 0,
        createdAt: msg.createdAt,
        updatedAt: msg.createdAt,
        lastMessage: msg,
      );
      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: MaterialApp(
            home: Scaffold(
              body: ChatGroupTile(group: group, narrow: false, onTap: () {}),
            ),
          ),
        ),
      );
      expect(
        find.text(
          chatMessageSummary(msg).text ?? chatMessageSummary(msg).label,
        ),
        findsOneWidget,
      );
      expect(find.text('2 members'), findsOneWidget);
    });
  }
}
