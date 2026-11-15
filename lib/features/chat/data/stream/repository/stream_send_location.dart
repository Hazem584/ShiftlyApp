import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import '../stream_chat_repository_base.dart';
import '../stream_chat_request.dart';

mixin StreamSendLocation on StreamChatRepositoryBase {
  @override
  Future<ChatMessage> sendLocation(
    String workspaceId,
    String groupId, {
    required ChatLocation location,
    required String clientMessageId,
  }) => streamChatRequest(() async {
    if (!await streamEnabled(workspaceId)) {
      return legacy.sendLocation(
        workspaceId,
        groupId,
        location: location,
        clientMessageId: clientMessageId,
      );
    }
    if (!location.isValid) throw const FormatException('Invalid location');
    return sendStreamMessage(
      workspaceId,
      groupId,
      stream.Message(
        id: clientMessageId,
        extraData: {'shiftly_location': location.toJson()},
      ),
    );
  });
}
