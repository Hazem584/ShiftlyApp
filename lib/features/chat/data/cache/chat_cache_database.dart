import 'package:sembast/sembast.dart';
import 'package:shiftly/core/storage/platform_file.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database_access.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database_base.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database_files.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database_purge.dart';
import 'package:shiftly/features/chat/data/cache/chat_database_factory.dart';

/// Private app-support storage. Grants are deliberately never persisted.
class ChatCacheDatabase extends ChatCacheDatabaseBase
    with
        ChatCacheDatabaseFiles,
        ChatCacheDatabaseAccess,
        ChatCacheDatabasePurge {
  ChatCacheDatabase(super.database, super.directory);

  static Future<ChatCacheDatabase> open(ChatStorageDirectory directory) async {
    await directory.create(recursive: true);
    final storage = ChatCacheDatabase(
      await openChatDatabase('${directory.path}/chat.db'),
      directory,
    );
    final records = await storage.records.find(storage.database);
    final owned = records
        .map((row) => row.value['file'])
        .whereType<String>()
        .toSet();
    await for (final entity in directory.list()) {
      final name = entity.uri.pathSegments.last;
      if (entity is ChatLocalFile &&
          chatOwnedFilePattern.hasMatch(name) &&
          !owned.contains(name)) {
        await entity.delete();
      }
    }
    return storage;
  }
}
