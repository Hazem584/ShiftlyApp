import 'package:sembast/sembast.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database.dart';
import 'package:shiftly/features/chat/data/cache/chat_group_codec.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_group_store.dart';

class ChatGroupCache implements ChatGroupStore {
  ChatGroupCache(this.storage);
  final ChatCacheDatabase storage;
  String _key(FeatureSessionScope scope) =>
      'groups:${scope.userId}:${scope.workspaceId}';

  @override
  Future<ChatGroupSnapshot?> read(FeatureSessionScope scope) async {
    final revision = storage.revision;
    await storage.ready;
    final value = await storage.records
        .record(_key(scope))
        .get(storage.database);
    if (revision != storage.revision ||
        value == null ||
        value['user'] != scope.userId ||
        value['workspace'] != scope.workspaceId) {
      return null;
    }
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;
    if (value['saved'] is! int || (value['saved'] as int) < cutoff) {
      return null;
    }
    try {
      final groups = (value['groups'] as List)
          .map((g) => ChatGroup.fromJson(chatMap(g)))
          .toList();
      if (groups.any((g) => g.workspaceId != scope.workspaceId)) return null;
      return (groups: groups, unreadCount: value['unread'] as int);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(FeatureSessionScope scope, ChatGroupSnapshot value) async {
    final revision = storage.revision;
    await storage.ready;
    if (revision != storage.revision) return;
    await storage.records.record(_key(scope)).put(storage.database, {
      'kind': 'groups',
      'user': scope.userId,
      'workspace': scope.workspaceId,
      'unread': value.unreadCount,
      'saved': DateTime.now().millisecondsSinceEpoch,
      'groups': value.groups.map(encodeCachedChatGroup).toList(),
    });
  }
}
