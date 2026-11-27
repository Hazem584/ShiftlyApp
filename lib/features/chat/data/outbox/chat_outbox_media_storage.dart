import 'dart:typed_data';

import 'package:shiftly/core/storage/platform_file.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_outbox_store.dart';
import 'package:uuid/uuid.dart';

abstract class ChatOutboxMediaStorage implements ChatOutboxStore {
  @override
  ChatCacheDatabase get storage;

  @override
  Future<String> ownMedia(ChatCacheScope scope, Uint8List bytes) async {
    await storage.ready;
    if (!storage.writable(scope)) throw StateError('Chat access unavailable');
    final name = '${const Uuid().v4()}.bin';
    final temporary = ChatLocalFile(
      '${storage.directory.path}/${const Uuid().v4()}.part',
    );
    final target = ChatLocalFile('${storage.directory.path}/$name');
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      if (!storage.writable(scope)) throw StateError('Chat access unavailable');
      await temporary.rename(target.path);
      return name;
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  @override
  ChatLocalFile mediaFile(String name) {
    if (!RegExp(r'^[a-f0-9-]+\.bin$').hasMatch(name)) {
      throw const FormatException('Invalid media');
    }
    return ChatLocalFile('${storage.directory.path}/$name');
  }
}
