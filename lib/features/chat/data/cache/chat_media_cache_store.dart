import 'package:dio/dio.dart';
import 'package:sembast/sembast.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/storage/platform_file.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_cache_lookup.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:uuid/uuid.dart';

extension ChatMediaCacheStoreExtension on ChatMediaCacheLookup {
  Future<ChatLocalFile> downloadAndStoreMedia(
    ChatCacheScope scope,
    ChatMessage msg,
    ChatRepository repo,
    String key,
    RecordRef<String, Map<String, Object?>> rec,
    void Function() check,
  ) async {
    await acquireTransferSlot();
    final token = CancelToken();
    tokens[key] = token;
    scopes[key] = scope;
    final name = '${const Uuid().v4()}.bin';
    final target = ChatLocalFile('${storage.directory.path}/$name');
    final temp = ChatLocalFile(
      '${storage.directory.path}/${const Uuid().v4()}.part',
    );
    try {
      check();
      final tx = await fetchMediaWithRetry(scope, msg, repo, temp, token, check);
      check();
      final digest = await inspectMediaFile(temp, msg, transformedImage: tx);
      if (digest == null) throw const FormatException('Invalid chat media');
      check();
      await temp.rename(target.path);
      check();
      await rec.put(storage.database, {
        'kind': 'media',
        'scope': scope.key,
        'user': scope.userId,
        'file': name,
        'size': await target.length(),
        'transformedImage': tx,
        'digest': digest,
        'access': DateTime.now().millisecondsSinceEpoch,
      });
      check();
      pin(target);
      try {
        await evict();
      } finally {
        unpin(target);
      }
      return target;
    } on ApiException catch (e) {
      if (e.statusCode == 403 ||
          (e.statusCode == 404 && e.code == 'CHAT_GROUP_NOT_FOUND')) {
        await storage.revoke(scope);
      }
      rethrow;
    } catch (_) {
      if (await target.exists()) await target.delete();
      rethrow;
    } finally {
      if (await temp.exists()) await temp.delete();
      tokens.remove(key);
      scopes.remove(key);
      releaseTransferSlot();
    }
  }
}
