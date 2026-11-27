import 'package:shiftly/features/chat/data/api/api_chat_group_operations.dart';
import 'package:shiftly/features/chat/data/api/api_chat_member_operations.dart';
import 'package:shiftly/features/chat/data/api/api_chat_message_actions.dart';
import 'package:shiftly/features/chat/data/api/api_chat_message_queries.dart';
import 'package:shiftly/features/chat/data/api/api_chat_repository_base.dart';
import 'package:shiftly/features/chat/data/api/api_chat_upload_completion.dart';
import 'package:shiftly/features/chat/data/api/api_chat_upload_operations.dart';

class ApiChatRepository extends ApiChatRepositoryBase
    with
        ApiChatGroupOperations,
        ApiChatMemberOperations,
        ApiChatMessageQueries,
        ApiChatMessageActions,
        ApiChatUploadOperations,
        ApiChatUploadCompletion {
  ApiChatRepository(super.dio, {required super.storageUploader});
}
