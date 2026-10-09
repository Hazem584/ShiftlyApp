import 'package:chatview/chatview.dart' as chatview;
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/presentation/adapters/chatview_message_adapter.dart';

void main() {
  const sender = ChatSender(
    membershipId: '33333333-3333-4333-8333-333333333333',
    profileId: '44444444-4444-4444-8444-444444444444',
    fullName: 'Ada Lovelace',
  );
  final createdAt = DateTime.utc(2026, 10, 4, 9, 30);

  for (final entry in const <String, ShiftlyChatPresentationKind>{
    'TEXT': ShiftlyChatPresentationKind.text,
    'IMAGE': ShiftlyChatPresentationKind.image,
    'VOICE': ShiftlyChatPresentationKind.voice,
    'LOCATION': ShiftlyChatPresentationKind.location,
    'FUTURE_TYPE': ShiftlyChatPresentationKind.unknown,
  }.entries) {
    test('maps ${entry.key} without changing canonical identity', () {
      final source = ChatMessage(
        id: '11111111-1111-4111-8111-111111111111',
        groupId: '22222222-2222-4222-8222-222222222222',
        type: entry.key,
        text: entry.key == 'TEXT' ? 'Hello' : null,
        sender: sender,
        createdAt: createdAt,
      );

      final adapted = ChatViewMessageAdapter.fromShiftly(source);

      expect(adapted.kind, entry.value);
      expect(adapted.message.id, source.id);
      expect(adapted.message.sentBy, sender.membershipId);
      expect(adapted.message.createdAt, createdAt);
      expect(adapted.message.messageType, chatview.MessageType.custom);
      expect(adapted.message.message, source.text ?? source.type);
    });
  }

  test('maps sender presentation without exposing another identifier', () {
    final user = ChatViewMessageAdapter.user(sender);

    expect(user.id, sender.membershipId);
    expect(user.name, sender.displayName);
    expect(user.profilePhoto, isNull);
  });
}
