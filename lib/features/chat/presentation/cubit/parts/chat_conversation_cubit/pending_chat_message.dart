part of '../../chat_conversation_cubit.dart';

class PendingChatMessage extends Equatable {
  const PendingChatMessage({
    required this.clientMessageId,
    required this.mediaType,
    required this.status,
    this.progress = 0,
    this.previewBytes,
    this.durationMs,
    this.failure,
  });

  final String clientMessageId;
  final PendingChatMediaType mediaType;
  final ChatUploadState status;
  final double progress;
  final Uint8List? previewBytes;
  final int? durationMs;
  final Failure? failure;

  PendingChatMessage copyWith({
    ChatUploadState? status,
    double? progress,
    bool clearPreview = false,
    Failure? failure,
    bool clearFailure = false,
  }) => PendingChatMessage(
    clientMessageId: clientMessageId,
    mediaType: mediaType,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    previewBytes: clearPreview ? null : previewBytes,
    durationMs: durationMs,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    clientMessageId,
    mediaType,
    status,
    progress,
    previewBytes,
    durationMs,
    failure,
  ];
}
