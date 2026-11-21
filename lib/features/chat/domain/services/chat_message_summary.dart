import 'package:shiftly/features/chat/domain/entities/chat_message.dart';

({String? text, String label}) chatMessageSummary(ChatMessage? message) {
  if (message == null) return (text: null, label: 'No messages yet');
  if (message.deletedAt != null) return (text: null, label: 'Message deleted');
  final text = message.text?.trim();
  if (text != null && text.isNotEmpty) return (text: text, label: '');
  return (
    text: null,
    label: switch (message.type) {
      'IMAGE' => 'Photo',
      'VOICE' => 'Voice message',
      'DOCUMENT' => 'Document',
      'LOCATION' => 'Location',
      _ => 'New message',
    },
  );
}
