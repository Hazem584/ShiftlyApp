import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/features/chat/data/signed_chat_upload_client.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';

abstract class ApiChatRepositoryBase extends ChatRepository {
  ApiChatRepositoryBase(
    this.dio, {
    required ChatStorageUploader storageUploader,
  }) : signedUploader = SignedChatUploadClient(storageUploader);

  final Dio dio;
  final SignedChatUploadClient signedUploader;

  String groupsPath(String workspaceId) =>
      '/workspaces/$workspaceId/chat/groups';
  String groupPath(String workspaceId, String groupId) =>
      '${groupsPath(workspaceId)}/$groupId';

  Future<T> request<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error) {
      throw ApiErrorParser.parse(error);
    }
  }

  ChatGroup parseGroup(Object? value) {
    return ChatGroup.fromJson(chatMap(value, 'chat group'));
  }

  List<String> uniqueUuids(List<String> values, String label) {
    if (values.length > 500) throw FormatException('Invalid $label');
    final unique = <String>{};
    for (final value in values) {
      final id = chatOptionalUuid(value);
      if (id == null) throw FormatException('Invalid $label');
      unique.add(id);
    }
    return unique.toList(growable: false);
  }

  void validateGroupFields(String name, String? description) {
    if (name.isEmpty || name.length > 80) {
      throw const FormatException('Invalid group name');
    }
    if (description != null && description.length > 500) {
      throw const FormatException('Invalid group description');
    }
  }

  String validatedMessageText(String value) {
    final text = value.trim();
    if (text.isEmpty || text.length > 4000) {
      throw const FormatException('Invalid message text');
    }
    return text;
  }
}
