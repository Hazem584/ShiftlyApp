import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/data/chat_image_gallery_download.dart';
import 'package:shiftly/features/chat/data/chat_image_gallery_validation.dart';
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
  final Dio _download;

  @override
  Future<void> save({
    required ChatMessage message,
    required ChatRepository repository,
    required FeatureSessionScope session,
    required bool Function() hasAccess,
    ChatMediaStore? cache,
  }) async {
    final att = message.attachment;
    if (message.type != 'IMAGE' ||
        att == null ||
        att.category != 'IMAGE' ||
        att.sizeBytes > ChatMediaValidation.imageMaxBytes) {
      throw const FormatException('Invalid chat image');
    }
    final scope = ChatCacheScope.fromSession(session, message.groupId);
    void check() {
      if (!hasAccess() || (cache != null && !cache.storage.authorized(scope))) {
        throw StateError('Chat access unavailable');
      }
    }

    check();
    final wId = session.workspaceId;
    final bytes = await loadChatGalleryBytes(
      _download,
      cache,
      scope,
      message,
      repository,
      wId,
      check,
    );
    check();
    final mime = await validateChatGalleryBytes(
      bytes,
      att,
      repository,
      wId,
      message,
      check,
    );
    await persistChatGalleryImage(_channel, bytes, mime, check);
  }
}
