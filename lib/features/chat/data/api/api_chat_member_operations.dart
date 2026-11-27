import 'package:shiftly/features/chat/data/api/api_chat_repository_base.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

mixin ApiChatMemberOperations on ApiChatRepositoryBase {
  @override
  Future<void> addMembers(
    String workspaceId,
    String groupId,
    List<String> membershipIds,
  ) => request(() async {
    final body = chatMap(
      (await dio.post<Object?>(
        '${groupPath(workspaceId, groupId)}/members',
        data: {'membershipIds': uniqueUuids(membershipIds, 'membershipIds')},
      )).data,
      'add members acknowledgement',
    );
    final count = body['addedCount'];
    if (count is! int || count < 0) {
      throw const FormatException('Invalid add members acknowledgement');
    }
  });

  @override
  Future<void> removeMember(
    String workspaceId,
    String groupId,
    String membershipId,
  ) => request(() async {
    final body = chatMap(
      (await dio.delete<Object?>(
        '${groupPath(workspaceId, groupId)}/members/$membershipId',
      )).data,
      'remove member acknowledgement',
    );
    if (body['removed'] != true) {
      throw const FormatException('Invalid remove member acknowledgement');
    }
  });

  @override
  Future<void> markRead(String workspaceId, String groupId, String messageId) =>
      request(() async {
        await dio.patch<Object?>(
          '${groupPath(workspaceId, groupId)}/read',
          data: {'messageId': messageId},
        );
      });

  @override
  Future<int> unreadCount(String workspaceId) => request(() async {
    final body = chatMap(
      (await dio.get<Object?>('/workspaces/$workspaceId/chat/unread-count'))
          .data,
      'unread count',
    );
    final value = body['count'];
    if (value is! int || value < 0) {
      throw const FormatException('Invalid unread count');
    }
    return value;
  });
}
