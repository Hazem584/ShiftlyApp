import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/entities/chat_upload_cancellation.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import 'pending_stream_upload.dart';
import 'stream_chat_connection.dart';
import 'stream_upload_filename.dart';
import 'stream_upload_validation.dart';

Future<void> uploadStreamFile(
  Map<String, PendingStreamUpload> pendingUploads,
  StreamChatConnection connection,
  ChatUploadAuthorization authorization,
  Uint8List bytes,
  String mime, {
  void Function(int, int)? onProgress,
  ChatUploadCancellation? cancellation,
}) async {
  final value = pendingUploads[authorization.uploadId];
  if (value == null) throw StateError('Upload session expired.');
  requireStreamUpload(
    pendingUploads,
    connection,
    authorization.uploadId,
    value.workspaceId,
    value.groupId,
  );
  if (value.authorization.uploadToken != authorization.uploadToken ||
      bytes.length != value.size ||
      mime != value.mime) {
    throw const FormatException('Invalid upload content');
  }
  final channel = await connection.channel(value.workspaceId, value.groupId);
  final cancel = CancelToken();
  cancellation?.bind(() => cancel.cancel());
  final file = stream.AttachmentFile(
    size: bytes.length,
    bytes: bytes,
    name: value.fileName ?? streamUploadFileName(value.type, value.mime),
  );
  try {
    final response = value.type == 'IMAGE'
        ? await channel.sendImage(
            file,
            onSendProgress: onProgress,
            cancelToken: cancel,
          )
        : await channel.sendFile(
            file,
            onSendProgress: onProgress,
            cancelToken: cancel,
          );
    requireStreamUpload(
      pendingUploads,
      connection,
      authorization.uploadId,
      value.workspaceId,
      value.groupId,
    );
    value.url = response.file;
  } finally {
    cancellation?.unbind();
  }
}
