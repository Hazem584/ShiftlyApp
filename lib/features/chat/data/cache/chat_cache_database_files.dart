import 'package:shiftly/core/storage/platform_file.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database_base.dart';

mixin ChatCacheDatabaseFiles on ChatCacheDatabaseBase {
  ChatLocalFile ownedFile(String name) {
    if (!chatOwnedFilePattern.hasMatch(name)) {
      throw const FormatException('Invalid private media');
    }
    return ChatLocalFile('${directory.path}/$name');
  }

  void pin(ChatLocalFile file) =>
      pins.update(file.path, (n) => n + 1, ifAbsent: () => 1);

  void unpin(ChatLocalFile file) {
    final count = (pins[file.path] ?? 0) - 1;
    if (count <= 0) {
      pins.remove(file.path);
      if (deferredDeletes.remove(file.path)) {
        unawaitedCleanup(deleteFile(file));
      }
    } else {
      pins[file.path] = count;
    }
  }

  Future<void> deleteFile(ChatLocalFile file) async {
    if (pins.containsKey(file.path)) {
      deferredDeletes.add(file.path);
      return;
    }
    if (await file.exists()) await file.delete();
  }
}
