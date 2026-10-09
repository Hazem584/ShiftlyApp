import 'package:equatable/equatable.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models_parsers.dart';

class ChatUploadAuthorization extends Equatable {
  const ChatUploadAuthorization({
    required this.uploadId,
    required this.bucket,
    required this.path,
    required this.uploadToken,
    required this.expiresAt,
    this.expectedMimeType,
    this.expectedSizeBytes,
  });

  final String uploadId;
  final String bucket;
  final String path;
  final String uploadToken;
  final DateTime expiresAt;
  final String? expectedMimeType;
  final int? expectedSizeBytes;

  factory ChatUploadAuthorization.fromJson(Map<String, Object?> json) {
    final url = json['signedUploadUrl'];
    final bucket = json['bucket'];
    final path = json['path'];
    final token = json['uploadToken'];
    final expires = json['expiresAt'];
    final uri = url is String ? Uri.tryParse(url) : null;
    final date = expires is String ? DateTime.tryParse(expires) : null;
    if (uri == null ||
        !uri.isAbsolute ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.fragment.isNotEmpty ||
        bucket != 'chat-media' ||
        !chatModelsValidStoragePath(path) ||
        token is! String ||
        token.trim().isEmpty ||
        date == null ||
        !date.isUtc ||
        !date.isAfter(DateTime.now().toUtc())) {
      throw const FormatException('Invalid upload authorization');
    }
    return ChatUploadAuthorization(
      uploadId: chatUuid(json, 'uploadId'),
      bucket: bucket as String,
      path: path as String,
      uploadToken: token,
      expiresAt: date.toUtc(),
    );
  }

  ChatUploadAuthorization withExpectedUpload({
    required String mimeType,
    required int sizeBytes,
  }) => ChatUploadAuthorization(
    uploadId: uploadId,
    bucket: bucket,
    path: path,
    uploadToken: uploadToken,
    expiresAt: expiresAt,
    expectedMimeType: mimeType,
    expectedSizeBytes: sizeBytes,
  );

  @override
  List<Object?> get props => [uploadId, expiresAt];

  @override
  String toString() =>
      'ChatUploadAuthorization($uploadId, expiresAt: $expiresAt)';
}
