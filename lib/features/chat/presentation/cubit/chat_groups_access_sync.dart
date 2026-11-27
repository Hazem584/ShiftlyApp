import 'dart:async';

import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_message_store.dart';

void syncChatGroupsCacheAccess(
  ChatMessageStore? messageCache,
  FeatureSessionScope scope,
  List<ChatGroup> previousGroups,
  List<ChatGroup> groups,
) {
  if (groups.any((group) => group.workspaceId != scope.workspaceId)) {
    throw const FormatException('Cross-workspace chat response');
  }
  final ids = groups.map((group) => group.id).toSet();
  for (final former in previousGroups) {
    if (!ids.contains(former.id)) {
      unawaited(
        messageCache?.storage.revoke(
              ChatCacheScope.fromSession(scope, former.id),
            ) ??
            Future<void>.value(),
      );
    }
  }
  for (final group in groups) {
    messageCache?.storage.grant(
      ChatCacheScope.fromSession(scope, group.id),
      archived: group.isArchived,
    );
  }
}

Failure chatGroupsFailure(Object error, String fallback) =>
    error is ApiException
        ? error.toFailure()
        : Failure(message: fallback, kind: FailureKind.server);
