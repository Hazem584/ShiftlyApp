import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:sembast/sembast_io.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_cache_access.dart';

/// Private app-support storage. Grants are deliberately never persisted.
class ChatCacheDatabase implements ChatCacheAccess {
  ChatCacheDatabase(this.database, this.directory);
  static Future<ChatCacheDatabase> open(Directory directory) async {
    await directory.create(recursive: true);
    final storage = ChatCacheDatabase(
      await databaseFactoryIo.openDatabase('${directory.path}/chat.db'),
      directory,
    );
    final records = await storage.records.find(storage.database);
    final owned = records
        .map((row) => row.value['file'])
        .whereType<String>()
        .toSet();
    await for (final entity in directory.list()) {
      final name = entity.uri.pathSegments.last;
      if (entity is File &&
          RegExp(r'^[a-f0-9-]+\.(bin|part)$').hasMatch(name) &&
          !owned.contains(name)) {
        await entity.delete();
      }
    }
    return storage;
  }

  final Database database;
  final Directory directory;
  final records = stringMapStoreFactory.store('private_chat');
  FeatureSessionScope? _session;
  final Set<String> _grants = {};
  final Set<String> _archived = {};
  @override
  final Set<void Function()> listeners = {};
  @override
  int revision = 0;
  final changes = ValueNotifier<int>(0);
  final _revisionEvents = StreamController<int>.broadcast(sync: true);
  @override
  Stream<int> get revisions => _revisionEvents.stream;
  Future<void> ready = Future<void>.value();
  final Map<String, int> pins = {};
  final Set<String> _deferredDeletes = {};
  File ownedFile(String name) {
    if (!RegExp(r'^[a-f0-9-]+\.(bin|part)$').hasMatch(name)) {
      throw const FormatException('Invalid private media');
    }
    return File('${directory.path}/$name');
  }

  void pin(File file) =>
      pins.update(file.path, (n) => n + 1, ifAbsent: () => 1);
  void unpin(File file) {
    final count = (pins[file.path] ?? 0) - 1;
    if (count <= 0) {
      pins.remove(file.path);
      if (_deferredDeletes.remove(file.path)) {
        unawaitedCleanup(deleteFile(file));
      }
    } else {
      pins[file.path] = count;
    }
  }

  Future<void> deleteFile(File file) async {
    if (pins.containsKey(file.path)) {
      _deferredDeletes.add(file.path);
      return;
    }
    if (await file.exists()) await file.delete();
  }

  @override
  bool authorized(ChatCacheScope scope) =>
      _session?.userId == scope.userId &&
      _session?.workspaceId == scope.workspaceId &&
      _grants.contains(scope.key);
  @override
  bool writable(ChatCacheScope scope) =>
      authorized(scope) && !_archived.contains(scope.key);
  @override
  void grant(ChatCacheScope scope, {bool archived = false}) {
    if (_session?.userId != scope.userId ||
        _session?.workspaceId != scope.workspaceId) {
      return;
    }
    _grants.add(scope.key);
    if (archived) {
      _archived.add(scope.key);
    } else {
      _archived.remove(scope.key);
    }
  }

  @override
  void bindSession(FeatureSessionScope? session) {
    if (_session == session) return;
    final former = _session?.userId;
    _session = session;
    _grants.clear();
    _archived.clear();
    revision++;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    for (final listener in listeners.toList()) {
      listener();
    }
    changes.value = revision;
    _revisionEvents.add(revision);
    if (former != null && former != session?.userId) {
      ready = ready.then((_) => purgeUser(former));
      unawaitedCleanup(ready);
    } else if (former == null && session != null) {
      // Remove leftovers from a process killed during a former user's logout.
      ready = ready.then(
        (_) => purge(Filter.notEquals('user', session.userId)),
      );
      unawaitedCleanup(ready);
    }
  }

  @override
  Future<void> revoke(ChatCacheScope scope) async {
    _grants.remove(scope.key);
    _archived.remove(scope.key);
    revision++;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    for (final listener in listeners.toList()) {
      listener();
    }
    changes.value = revision;
    _revisionEvents.add(revision);
    await purge(Filter.equals('scope', scope.key));
  }

  Future<void> purgeUser(String userId) => purge(Filter.equals('user', userId));
  Future<void> purge(Filter filter) async {
    final values = await database.transaction((transaction) async {
      final rows = await records.find(
        transaction,
        finder: Finder(filter: filter),
      );
      await records.delete(transaction, finder: Finder(filter: filter));
      return rows;
    });
    // Sembast is append-only between compactions; rewrite away revoked payloads.
    await database.compact();
    // Names are generated UUIDs, never supplied filenames or remote paths.
    for (final value in values) {
      final filename = value.value['file'];
      if (filename is String &&
          RegExp(r'^[a-f0-9-]+\.(bin|part)$').hasMatch(filename)) {
        final file = File('${directory.path}/$filename');
        if (await file.exists()) await file.delete();
      }
    }
  }

  void unawaitedCleanup(Future<void> work) {
    work.catchError((Object _) {
      /* A later authorized open retries cleanup. */
    });
  }

  Future<void> close() async {
    await ready;
    listeners.clear();
    changes.dispose();
    await _revisionEvents.close();
    await database.close();
  }
}
