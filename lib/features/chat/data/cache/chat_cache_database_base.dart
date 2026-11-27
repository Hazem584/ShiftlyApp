import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:sembast/sembast.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/storage/platform_file.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_cache_access.dart';

final RegExp chatOwnedFilePattern = RegExp(r'^[a-f0-9-]+\.(bin|part)$');

abstract class ChatCacheDatabaseBase implements ChatCacheAccess {
  ChatCacheDatabaseBase(this.database, this.directory);

  final Database database;
  final ChatStorageDirectory directory;
  final records = stringMapStoreFactory.store('private_chat');
  FeatureSessionScope? session;
  final Set<String> grants = {};
  final Set<String> archived = {};
  @override
  final Set<void Function()> listeners = {};
  @override
  int revision = 0;
  final changes = ValueNotifier<int>(0);
  final revisionEvents = StreamController<int>.broadcast(sync: true);
  @override
  Stream<int> get revisions => revisionEvents.stream;
  Future<void> ready = Future<void>.value();
  final Map<String, int> pins = {};
  final Set<String> deferredDeletes = {};

  void notifyRevision({bool clearImages = false}) {
    revision++;
    if (clearImages) {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    }
    for (final listener in listeners.toList()) {
      listener();
    }
    changes.value = revision;
    revisionEvents.add(revision);
  }

  void unawaitedCleanup(Future<void> work) {
    work.catchError((Object _) {});
  }

  Future<void> close() async {
    await ready;
    listeners.clear();
    changes.dispose();
    await revisionEvents.close();
    await database.close();
  }
}
