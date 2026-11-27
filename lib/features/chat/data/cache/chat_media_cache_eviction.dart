import 'package:sembast/sembast.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_cache_base.dart';

final RegExp chatMediaFilePattern = RegExp(r'^[a-f0-9-]+\.bin$');

String? canonicalChatMediaMime(String? mime) => switch (mime?.toLowerCase()) {
  'audio/x-m4a' || 'audio/m4a' || 'video/mp4' => 'audio/mp4',
  'image/jpg' => 'image/jpeg',
  final value => value,
};

mixin ChatMediaCacheEviction on ChatMediaCacheBase {
  @override
  Future<int> size() async {
    final rows = await storage.records.find(
      storage.database,
      finder: Finder(filter: Filter.equals('kind', 'media')),
    );
    return rows.fold<int>(
      0,
      (total, row) => total + (row.value['size'] as int),
    );
  }

  @override
  Future<void> clear() => evict(clear: true);

  Future<void> evict({bool clear = false}) async {
    final rows = await storage.records.find(
      storage.database,
      finder: Finder(
        filter: Filter.equals('kind', 'media'),
        sortOrders: [SortOrder('access')],
      ),
    );
    var total = rows.fold<int>(
      0,
      (sum, row) => sum + (row.value['size'] as int),
    );
    for (final row in rows) {
      final name = row.value['file'];
      if (name is! String || !chatMediaFilePattern.hasMatch(name)) {
        await storage.records.record(row.key).delete(storage.database);
        continue;
      }
      final file = storage.ownedFile(name);
      if (storage.pins.containsKey(file.path)) continue;
      final cutoff = DateTime.now().subtract(retention).millisecondsSinceEpoch;
      if (clear || total > byteLimit || (row.value['access'] as int) < cutoff) {
        if (await file.exists()) await file.delete();
        await storage.records.record(row.key).delete(storage.database);
        total -= row.value['size'] as int;
      }
    }
  }
}
