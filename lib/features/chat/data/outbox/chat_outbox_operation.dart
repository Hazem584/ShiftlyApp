import 'package:shiftly/features/chat/data/chat_models.dart';

class ChatOutboxOperation {
  ChatOutboxOperation({
    required this.id,
    required this.type,
    required this.createdAt,
    this.text,
    this.location,
    this.file,
    this.mimeType,
    this.sizeBytes,
    this.durationMs,
    this.phase = 'queued',
    this.uploadId,
    this.submitted = false,
  });
  final String id;
  final String type;
  final DateTime createdAt;
  final String? text;
  final ChatLocation? location;
  final String? file;
  final String? mimeType;
  final int? sizeBytes;
  final int? durationMs;
  String phase;
  String? uploadId;
  bool submitted;
  Map<String, Object?> toJson() => {
    'id': id,
    'type': type,
    'created': createdAt.toIso8601String(),
    'text': text,
    'location': location?.toJson(),
    'file': file,
    'mime': mimeType,
    'size': sizeBytes,
    'duration': durationMs,
    'phase': phase,
    'uploadId': uploadId,
    'submitted': submitted,
  };
  factory ChatOutboxOperation.fromJson(Map<String, Object?> value) =>
      ChatOutboxOperation(
        id: value['id'] as String,
        type: value['type'] as String,
        createdAt: DateTime.parse(value['created'] as String),
        text: value['text'] as String?,
        location: value['location'] == null
            ? null
            : ChatLocation.fromJson(chatMap(value['location'])),
        file: value['file'] as String?,
        mimeType: value['mime'] as String?,
        sizeBytes: value['size'] as int?,
        durationMs: value['duration'] as int?,
        phase: value['phase'] as String,
        uploadId: value['uploadId'] as String?,
        submitted: value['submitted'] as bool,
      );
}
