import 'dart:typed_data';

import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/entities/chat_upload_cancellation.dart';

import '../stream_chat_repository_base.dart';
import '../stream_chat_request.dart';

mixin StreamUploadSigned on StreamChatRepositoryBase {
  @override
  Future<void> uploadSigned(
    ChatUploadAuthorization authorization,
    Uint8List bytes,
    String mimeType, {
    void Function(int, int)? onProgress,
    ChatUploadCancellation? cancellation,
  }) => streamChatRequest(() async {
    if (authorization.bucket != 'stream-chat') {
      return legacy.uploadSigned(
        authorization,
        bytes,
        mimeType,
        onProgress: onProgress,
        cancellation: cancellation,
      );
    }
    return media.upload(
      authorization,
      bytes,
      mimeType,
      onProgress: onProgress,
      cancellation: cancellation,
    );
  });
}
