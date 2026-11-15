import 'dart:typed_data';

import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/entities/chat_upload_cancellation.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import 'pending_stream_upload.dart';
import 'stream_chat_connection.dart';
import 'stream_upload_attachment.dart';
import 'stream_upload_cancel.dart';
import 'stream_upload_file.dart';
import 'stream_upload_prepare.dart';
import 'stream_upload_validation.dart';

export 'pending_stream_upload.dart';

class StreamChatMedia {
  StreamChatMedia(this.connection);
  final StreamChatConnection connection;
  final _pending = <String, PendingStreamUpload>{};
  void reset() => _pending.clear();
  ChatUploadAuthorization prepare(
    String workspaceId,
    String groupId, {
    required String type,
    required String mimeType,
    required int sizeBytes,
    int? durationMs,
    String? fileName,
  }) => prepareStreamUpload(
    _pending,
    connection,
    workspaceId,
    groupId,
    type: type,
    mimeType: mimeType,
    sizeBytes: sizeBytes,
    durationMs: durationMs,
    fileName: fileName,
  );
  PendingStreamUpload pending(String id, String workspaceId, String groupId) =>
      requireStreamUpload(_pending, connection, id, workspaceId, groupId);
  Future<void> upload(
    ChatUploadAuthorization authorization,
    Uint8List bytes,
    String mime, {
    void Function(int, int)? onProgress,
    ChatUploadCancellation? cancellation,
  }) => uploadStreamFile(
    _pending,
    connection,
    authorization,
    bytes,
    mime,
    onProgress: onProgress,
    cancellation: cancellation,
  );
  stream.Attachment attachment(String id, String workspaceId, String groupId) =>
      streamUploadAttachment(id, pending(id, workspaceId, groupId));
  void complete(String id) => _pending.remove(id);
  Future<void> cancel(String workspaceId, String groupId, String id) =>
      cancelStreamUpload(_pending, connection, workspaceId, groupId, id);
}
