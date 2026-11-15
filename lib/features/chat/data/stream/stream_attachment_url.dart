import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

ChatMediaUrl streamAttachmentUrl(
  stream.GetMessageResponse response,
  String groupId,
) {
  final message = response.message;
  final cid = response.channel?.cid ?? message.extraData['cid'];
  if (cid != 'shiftly:$groupId' || message.deletedAt != null) {
    throw const FormatException('Chat attachment is no longer available');
  }
  final attachment = message.attachments.firstOrNull;
  final image = attachment?.type == 'image';
  final candidates = image
      ? [attachment?.imageUrl, attachment?.assetUrl]
      : [attachment?.assetUrl];
  final uri = candidates
      .whereType<String>()
      .map(Uri.tryParse)
      .whereType<Uri>()
      .where(
        (value) =>
            value.scheme == 'https' &&
            value.host.isNotEmpty &&
            value.userInfo.isEmpty,
      )
      .firstOrNull;
  if (uri == null) throw const FormatException('Invalid chat attachment URL');
  return ChatMediaUrl(
    url: uri,
    expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
    allowImageTransformation: image,
  );
}
