import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_media_store.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/domain/services/chat_media_validation.dart';

Future<Uint8List> loadChatGalleryBytes(
  Dio download,
  ChatMediaStore? cache,
  ChatCacheScope scope,
  ChatMessage message,
  ChatRepository repository,
  String workspaceId,
  void Function() checkAccess,
) async {
  if (cache != null) {
    final file = await cache.resolve(scope, message, repository);
    cache.pin(file);
    try {
      return await file.readAsBytes();
    } finally {
      cache.unpin(file);
    }
  }
  for (var attempt = 0; ; attempt++) {
    final signed = await repository.mediaUrl(
      workspaceId,
      message.groupId,
      message.id,
    );
    checkAccess();
    try {
      final response = await download.get<ResponseBody>(
        signed.url.toString(),
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: false,
        ),
      );
      final body = response.data;
      if (body == null) throw const FormatException('Empty image');
      final buffer = BytesBuilder(copy: false);
      final max = signed.allowImageTransformation
          ? ChatMediaValidation.imageMaxBytes
          : message.attachment!.sizeBytes;
      await for (final chunk in body.stream) {
        checkAccess();
        if (buffer.length + chunk.length > max) {
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
