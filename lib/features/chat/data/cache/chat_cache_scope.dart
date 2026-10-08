import 'dart:convert';

import 'package:shiftly/core/session/feature_scope.dart';

class ChatCacheScope {
  const ChatCacheScope(this.userId, this.workspaceId, this.groupId);
  factory ChatCacheScope.fromSession(
    FeatureSessionScope scope,
    String groupId,
  ) => ChatCacheScope(scope.userId, scope.workspaceId, groupId);
  final String userId;
  final String workspaceId;
  final String groupId;
  String get key => jsonEncode([userId, workspaceId, groupId]);
}
