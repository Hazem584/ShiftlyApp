import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';

/// Session-bound access to private cached conversations.
abstract interface class ChatCacheAccess {
  int get revision;
  Stream<int> get revisions;
  Set<void Function()> get listeners;
  bool authorized(ChatCacheScope scope);
  bool writable(ChatCacheScope scope);
  void grant(ChatCacheScope scope, {bool archived = false});
  void bindSession(FeatureSessionScope? session);
  Future<void> revoke(ChatCacheScope scope);
}
