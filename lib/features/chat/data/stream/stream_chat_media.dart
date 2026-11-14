import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/entities/chat_upload_cancellation.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;
import 'package:uuid/uuid.dart';

import 'stream_chat_connection.dart';

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
  }) {
    final scope = connection.scope;
    if (scope == null ||
        scope.workspaceId != workspaceId ||
        !['IMAGE', 'VOICE', 'DOCUMENT'].contains(type) ||
        sizeBytes <= 0 ||
        sizeBytes > 25 * 1024 * 1024) {
      throw const FormatException('Invalid chat upload');
    }
    final id = const Uuid().v4(), token = const Uuid().v4();
    final authorization = ChatUploadAuthorization(
      uploadId: id,
      bucket: 'stream-chat',
      path: '$workspaceId/$groupId/$id',
      uploadToken: token,
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
      expectedMimeType: mimeType,
      expectedSizeBytes: sizeBytes,
    );
    _pending[id] = PendingStreamUpload(
      scope,
      authorization,
      workspaceId,
      groupId,
      type,
      mimeType,
      sizeBytes,
      durationMs,
      fileName,
    );
    return authorization;
  }

  PendingStreamUpload pending(String id, String workspaceId, String groupId) {
    final value = _pending[id];
    if (value == null ||
        value.scope != connection.scope ||
        value.workspaceId != workspaceId ||
        value.groupId != groupId ||
        value.authorization.expiresAt.isBefore(DateTime.now().toUtc())) {
      throw StateError('Upload session expired.');
    }
    return value;
  }

  Future<void> upload(
    ChatUploadAuthorization authorization,
    Uint8List bytes,
    String mime, {
    void Function(int, int)? onProgress,
    ChatUploadCancellation? cancellation,
  }) async {
    final value = _pending[authorization.uploadId];
    if (value == null) throw StateError('Upload session expired.');
    pending(authorization.uploadId, value.workspaceId, value.groupId);
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
      name:
          value.fileName ??
          (value.type == 'IMAGE'
              ? 'image.jpg'
              : value.type == 'VOICE'
              ? 'voice.m4a'
              : 'document.bin'),
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
      pending(authorization.uploadId, value.workspaceId, value.groupId);
      value.url = response.file;
    } finally {
      cancellation?.unbind();
    }
  }

  stream.Attachment attachment(String id, String workspaceId, String groupId) {
    final value = pending(id, workspaceId, groupId), url = value.url;
    if (url == null) throw StateError('Upload is not complete.');
    return stream.Attachment(
      id: id,
      type: value.type == 'IMAGE'
          ? 'image'
          : value.type == 'VOICE'
          ? 'audio'
          : 'file',
      title:
          value.fileName ??
          (value.type == 'VOICE' ? 'Voice message' : 'Attachment'),
      imageUrl: value.type == 'IMAGE' ? url : null,
      assetUrl: url,
      uploadState: const stream.UploadState.success(),
      extraData: {
        'shiftly_attachment_id': id,
        'file_size': value.size,
        'mime_type': value.mime,
        if (value.duration != null) 'shiftly_duration_ms': value.duration,
      },
    );
  }

  void complete(String id) => _pending.remove(id);
  Future<void> cancel(String workspaceId, String groupId, String id) async {
    final value = _pending[id];
    if (value == null) return;
    pending(id, workspaceId, groupId);
    _pending.remove(id);
    if (value.url != null) {
      final channel = await connection.channel(workspaceId, groupId);
      if (value.type == 'IMAGE') {
        await channel.deleteImage(value.url!);
      } else {
        await channel.deleteFile(value.url!);
      }
    }
  }
}

class PendingStreamUpload {
  PendingStreamUpload(
    this.scope,
    this.authorization,
    this.workspaceId,
    this.groupId,
    this.type,
    this.mime,
    this.size,
    this.duration,
    this.fileName,
  );
  final FeatureSessionScope scope;
  final ChatUploadAuthorization authorization;
  final String workspaceId, groupId, type, mime;
  final int size;
  final int? duration;
  final String? fileName;
  String? url;
}
