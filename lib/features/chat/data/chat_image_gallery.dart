import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_gallery.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_media_store.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/domain/services/chat_media_validation.dart';

class ChatImageGallery implements ChatGallery {
  ChatImageGallery({MethodChannel? channel, Dio? downloadClient})
    : _channel = channel ?? const MethodChannel('shiftly/chat_gallery'),
      _download =
          downloadClient ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 45),
            ),
          );

  final MethodChannel _channel;
  // Signed storage URLs must not receive the API client's authorization headers.
  final Dio _download;

  @override
  Future<void> save({
    required ChatMessage message,
    required ChatRepository repository,
    required FeatureSessionScope session,
    required bool Function() hasAccess,
    ChatMediaStore? cache,
  }) async {
    final attachment = message.attachment;
    if (message.type != 'IMAGE' ||
        attachment == null ||
        attachment.category != 'IMAGE' ||
        attachment.sizeBytes > ChatMediaValidation.imageMaxBytes) {
      throw const FormatException('Invalid chat image');
    }
    final scope = ChatCacheScope.fromSession(session, message.groupId);
    void checkAccess() {
      if (!hasAccess() || (cache != null && !cache.storage.authorized(scope))) {
        throw StateError('Chat access unavailable');
      }
    }

    checkAccess();
    Uint8List bytes;
    if (cache != null) {
      final file = await cache.resolve(scope, message, repository);
      cache.pin(file);
      try {
        bytes = await file.readAsBytes();
      } finally {
        cache.unpin(file);
      }
    } else {
      bytes = await _downloadImage(
        repository,
        session.workspaceId,
        message,
        checkAccess,
      );
    }
    checkAccess();
    final mime = ChatMediaValidation.imageMime(bytes);
    if (bytes.length != attachment.sizeBytes ||
        mime == null ||
        mime != attachment.mimeType) {
      throw const FormatException('Invalid chat image');
    }
    final extension = switch (mime) {
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      _ => 'webp',
    };
    final saved = await _channel.invokeMethod<bool>('saveImage', {
      'bytes': bytes,
      'mimeType': mime,
      'name':
          'shiftly_${DateTime.now().toUtc().microsecondsSinceEpoch}.$extension',
    });
    if (saved != true) throw StateError('Image was not saved');
  }

  Future<Uint8List> _downloadImage(
    ChatRepository repository,
    String workspaceId,
    ChatMessage message,
    void Function() checkAccess,
  ) async {
    for (var attempt = 0; ; attempt++) {
      final signed = await repository.mediaUrl(
        workspaceId,
        message.groupId,
        message.id,
      );
      checkAccess();
      try {
        final response = await _download.get<ResponseBody>(
          signed.url.toString(),
          options: Options(
            responseType: ResponseType.stream,
            followRedirects: false,
          ),
        );
        final body = response.data;
        if (body == null) throw const FormatException('Empty image');
        final buffer = BytesBuilder(copy: false);
        await for (final chunk in body.stream) {
          checkAccess();
          if (buffer.length + chunk.length > message.attachment!.sizeBytes) {
            throw const FormatException('Invalid image size');
          }
          buffer.add(chunk);
        }
        return buffer.takeBytes();
      } on DioException catch (error) {
        if (attempt != 0 ||
            !const [401, 403].contains(error.response?.statusCode)) {
          rethrow;
        }
      }
    }
  }
}
