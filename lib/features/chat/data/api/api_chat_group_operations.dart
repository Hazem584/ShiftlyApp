import 'package:shiftly/features/chat/data/api/api_chat_repository_base.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

mixin ApiChatGroupOperations on ApiChatRepositoryBase {
  @override
  Future<List<ChatGroup>> listGroups(String workspaceId) => request(() async {
    final body = chatMap(
      (await dio.get<Object?>(groupsPath(workspaceId))).data,
      'chat groups response',
    );
    return chatList(body['data'], 'chat groups')
        .map((e) => ChatGroup.fromJson(chatMap(e, 'chat group')))
        .toList(growable: false);
  });

  @override
  Future<ChatGroup> getGroup(String workspaceId, String groupId) => request(
    () async => parseGroup(
      (await dio.get<Object?>(groupPath(workspaceId, groupId))).data,
    ),
  );

  @override
  Future<ChatGroup> createGroup(
    String workspaceId, {
    required String name,
    String? description,
    required List<String> memberMembershipIds,
  }) => request(() async {
    final trimmedName = name.trim();
    final desc = description?.trim();
    validateGroupFields(trimmedName, desc);
    final ids = uniqueUuids(memberMembershipIds, 'memberMembershipIds');
    return parseGroup(
      (await dio.post<Object?>(
        groupsPath(workspaceId),
        data: {
          'name': trimmedName,
          if (desc?.isNotEmpty == true) 'description': desc,
          'memberMembershipIds': ids,
        },
      )).data,
    );
  });

  @override
  Future<void> updateGroup(
    String workspaceId,
    String groupId, {
    required String name,
    String? description,
  }) => request(() async {
    final trimmedName = name.trim();
    final desc = description?.trim();
    validateGroupFields(trimmedName, desc);
    await dio.patch<Object?>(
      groupPath(workspaceId, groupId),
      data: {
        'name': trimmedName,
        'description': desc?.isEmpty == true ? null : desc,
      },
    );
  });

  @override
  Future<void> archiveGroup(String workspaceId, String groupId) => request(
    () async =>
        dio.patch<Object?>('${groupPath(workspaceId, groupId)}/archive'),
  );
}
