import 'dart:convert';

import 'package:sembast/sembast.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/storage/platform_file.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database_access.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database_base.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';

mixin ChatCacheDatabasePurge
    on ChatCacheDatabaseBase, ChatCacheDatabaseAccess {
  @override
  void bindSession(FeatureSessionScope? session) {
    final former = updateSessionState(session);
    if (former == null) return;
    if (former.isNotEmpty && former != session?.userId) {
      unawaitedCleanup(ready = ready.then((_) => purgeUser(former)));
    } else if (former.isEmpty && session != null) {
      final filter = Filter.notEquals('user', session.userId);
      unawaitedCleanup(ready = ready.then((_) => purge(filter)));
    }
  }

  @override
  Future<void> revoke(ChatCacheScope scope) async {
    grants.remove(scope.key);
    archived.remove(scope.key);
    notifyRevision(clearImages: true);
    await purge(Filter.equals('scope', scope.key));
  }

  Future<void> purgeWorkspace(String userId, String workspaceId) async {
    final enc = jsonEncode([userId, workspaceId]);
    final prefix = '${enc.substring(0, enc.length - 1)},';
    grants.removeWhere((k) => k.startsWith(prefix));
    archived.removeWhere((k) => k.startsWith(prefix));
    notifyRevision();
    final rows = await records.find(
      database,
      finder: Finder(filter: Filter.equals('user', userId)),
    );
    final scopes = rows
        .map((r) => r.value['scope'])
        .whereType<String>()
        .where((k) => k.startsWith(prefix))
        .toSet()
        .toList();
    await purge(
      Filter.and([
        Filter.equals('user', userId),
        Filter.or([
          Filter.equals('workspace', workspaceId),
          Filter.inList('scope', scopes),
        ]),
      ]),
    );
  }

  Future<void> purgeUser(String userId) => purge(Filter.equals('user', userId));

  Future<void> purge(Filter filter) async {
    final values = await database.transaction((tx) async {
      final rows = await records.find(tx, finder: Finder(filter: filter));
      await records.delete(tx, finder: Finder(filter: filter));
      return rows;
    });
    await database.compact();
    for (final value in values) {
      final name = value.value['file'];
      if (name is String && chatOwnedFilePattern.hasMatch(name)) {
        final file = ChatLocalFile('${directory.path}/$name');
        if (await file.exists()) await file.delete();
      }
    }
  }
}
