import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database_base.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';

mixin ChatCacheDatabaseAccess on ChatCacheDatabaseBase {
  @override
  bool authorized(ChatCacheScope scope) =>
      session?.userId == scope.userId &&
      session?.workspaceId == scope.workspaceId &&
      grants.contains(scope.key);

  @override
  bool writable(ChatCacheScope scope) =>
      authorized(scope) && !archived.contains(scope.key);

  @override
  void grant(ChatCacheScope scope, {bool archived = false}) {
    if (session?.userId != scope.userId ||
        session?.workspaceId != scope.workspaceId) {
      return;
    }
    grants.add(scope.key);
    if (archived) {
      this.archived.add(scope.key);
    } else {
      this.archived.remove(scope.key);
    }
  }

  String? updateSessionState(FeatureSessionScope? nextSession) {
    if (session == nextSession) return null;
    final former = session?.userId;
    session = nextSession;
    grants.clear();
    archived.clear();
    notifyRevision(clearImages: true);
    return former ?? '';
  }
}
