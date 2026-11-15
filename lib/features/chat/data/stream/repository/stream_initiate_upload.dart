import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

import '../stream_chat_repository_base.dart';
import '../stream_chat_request.dart';

mixin StreamInitiateUpload on StreamChatRepositoryBase {
  @override
  Future<ChatUploadAuthorization> initiateUpload(
    String workspaceId,
    String groupId, {
    required String type,
    required String mimeType,
    required int sizeBytes,
    int? durationMs,
    String? fileName,
  }) => streamChatRequest(() async {
    if (!await streamEnabled(workspaceId)) {
      return legacy.initiateUpload(
        workspaceId,
        groupId,
        type: type,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        durationMs: durationMs,
        fileName: fileName,
      );
    }
    await connection.channel(workspaceId, groupId);
    return media.prepare(
      workspaceId,
      groupId,
      type: type,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      durationMs: durationMs,
      fileName: fileName,
    );
  });
}
