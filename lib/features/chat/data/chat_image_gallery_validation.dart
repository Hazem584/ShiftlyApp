import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/domain/services/chat_media_validation.dart';

Future<String> validateChatGalleryBytes(
  Uint8List bytes,
  ChatAttachment attachment,
  ChatRepository repository,
  String workspaceId,
  ChatMessage message,
  void Function() checkAccess,
) async {
  final mime = ChatMediaValidation.imageMime(bytes);
  if (mime == null) throw const FormatException('Invalid chat image');
  if (bytes.length != attachment.sizeBytes || mime != attachment.mimeType) {
    final rep = await repository.mediaUrl(
      workspaceId,
      message.groupId,
      message.id,
    );
    checkAccess();
    if (!rep.allowImageTransformation) {
      throw const FormatException('Invalid chat image');
    }
  }
  return mime;
}

Future<void> persistChatGalleryImage(
  MethodChannel channel,
  Uint8List bytes,
  String mime,
  void Function() check,
) async {
  final ext = switch (mime) {
    'image/jpeg' => 'jpg',
    'image/png' => 'png',
    _ => 'webp',
  };
  final name = 'shiftly_${DateTime.now().toUtc().microsecondsSinceEpoch}.$ext';
  if (kIsWeb) {
    check();
    await XFile.fromData(bytes, mimeType: mime, name: name).saveTo(name);
    return;
  }
  final saved = await channel.invokeMethod<bool>('saveImage', {
    'bytes': bytes,
    'mimeType': mime,
    'name': name,
  });
  if (saved != true) throw StateError('Image was not saved');
}
