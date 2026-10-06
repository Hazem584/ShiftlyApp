part of '../../chat_models.dart';

class ChatAttachment extends Equatable {
  const ChatAttachment({
    required this.id,
    required this.category,
    required this.mimeType,
    required this.sizeBytes,
    this.durationMs,
  });

  final String id;
  final String category;
  final String mimeType;
  final int sizeBytes;
  final int? durationMs;

  factory ChatAttachment.fromJson(Map<String, Object?> json) {
    final size = json['sizeBytes'];
    final duration = json['durationMs'];
    if (size is! int || size < 1 || (duration != null && duration is! int)) {
      throw const FormatException('Invalid attachment metadata');
    }
    return ChatAttachment(
      id: chatUuid(json, 'id'),
      category: _text(json, 'category'),
      mimeType: _text(json, 'mimeType'),
      sizeBytes: size,
      durationMs: duration as int?,
    );
  }

  @override
  List<Object?> get props => [id, category, mimeType, sizeBytes, durationMs];
}
