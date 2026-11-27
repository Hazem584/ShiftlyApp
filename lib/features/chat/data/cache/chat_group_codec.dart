import 'package:shiftly/features/chat/data/cache/chat_message_codec.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

Map<String, Object?> encodeCachedChatGroup(ChatGroup g) => <String, Object?>{
  'id': g.id,
  'workspaceId': g.workspaceId,
  'name': g.name,
  'description': g.description,
  'memberCount': g.memberCount,
  'unreadCount': g.unreadCount,
  'createdAt': g.createdAt.toIso8601String(),
  'updatedAt': g.updatedAt.toIso8601String(),
  'archivedAt': g.archivedAt?.toIso8601String(),
  'archived': g.isArchived,
  if (g.lastMessage != null)
    'lastMessage': ChatMessageCodec.encode(g.lastMessage!),
};
