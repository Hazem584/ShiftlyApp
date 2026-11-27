import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

List<ChatMessage> mergeChatMessages(
  List<ChatMessage> incoming,
  List<ChatMessage> current,
) {
  final byId = <String, ChatMessage>{
    for (final item in current) item.id: item,
  };
  for (final item in incoming) {
    if ((byId[item.id]?.revision ?? -1) <= item.revision) {
      byId[item.id] = item;
    }
  }
  return [...byId.values]..sort((a, b) {
      final byTime = a.createdAt.compareTo(b.createdAt);
      return byTime == 0 ? a.id.compareTo(b.id) : byTime;
    });
}

void validateChatMessages(
  List<ChatMessage> values,
  FeatureSessionScope scope,
  String groupId,
) {
  if (values.any((item) => item.groupId != groupId)) {
    throw const FormatException('Cross-group message response');
  }
}

Failure chatConversationFailure(Object error, String fallback) =>
    error is ApiException
        ? error.toFailure()
        : Failure(message: fallback, kind: FailureKind.server);

bool isChatAccessLost(Object error) =>
    error is ApiException &&
    (error.statusCode == 403 ||
        (error.statusCode == 404 && error.code == 'CHAT_GROUP_NOT_FOUND'));
