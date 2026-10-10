@TestOn('browser')
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/storage/platform_file.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database.dart';
import 'package:shiftly/features/chat/data/outbox/chat_outbox_storage.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_outbox_operation.dart';

const session = FeatureSessionScope(
  userId: 'web-user',
  workspaceId: 'web-workspace',
  membershipId: 'web-member',
  timezone: 'Etc/UTC',
  role: WorkspaceRole.employee,
);
const scope = ChatCacheScope('web-user', 'web-workspace', 'web-group');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'browser outbox survives reopen, requires fresh access, purges on logout',
    () async {
      final directory = ChatStorageDirectory(
        'test-${DateTime.now().microsecondsSinceEpoch}',
      );
      var storage = await ChatCacheDatabase.open(directory);
      storage.bindSession(session);
      await storage.ready;
      storage.grant(scope);
      var outbox = ChatOutboxStorage(storage);
      final bytes = Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]);
      final name = await outbox.ownMedia(scope, bytes);
      await outbox.save(
        scope,
        ChatOutboxOperation(
          id: 'web-message',
          type: 'IMAGE',
          createdAt: DateTime.now(),
          file: name,
          mimeType: 'image/jpeg',
          sizeBytes: bytes.length,
        ),
      );
      await storage.close();

      storage = await ChatCacheDatabase.open(directory);
      outbox = ChatOutboxStorage(storage);
      expect(await outbox.restore(scope), isEmpty);
      storage.bindSession(session);
      await storage.ready;
      storage.grant(scope);
      expect((await outbox.restore(scope)).single.id, 'web-message');
      expect(await outbox.mediaFile(name).readAsBytes(), bytes);
      storage.bindSession(null);
      await storage.ready;
      expect(await outbox.restore(scope), isEmpty);
      expect(await outbox.mediaFile(name).exists(), isFalse);
      await storage.close();
    },
  );

  test(
    'archived browser chat blocks writes and revocation deletes owned bytes',
    () async {
      final storage = await ChatCacheDatabase.open(
        ChatStorageDirectory('test-${DateTime.now().microsecondsSinceEpoch}'),
      );
      storage.bindSession(session);
      await storage.ready;
      storage.grant(scope);
      final outbox = ChatOutboxStorage(storage);
      final name = await outbox.ownMedia(scope, Uint8List.fromList([1, 2, 3]));
      await outbox.save(
        scope,
        ChatOutboxOperation(
          id: 'pending',
          type: 'VOICE',
          createdAt: DateTime.now(),
          file: name,
        ),
      );
      storage.grant(scope, archived: true);
      await expectLater(
        outbox.ownMedia(scope, Uint8List.fromList([4])),
        throwsStateError,
      );
      await storage.revoke(scope);
      expect(await outbox.mediaFile(name).exists(), isFalse);
      expect(storage.authorized(scope), isFalse);
      await storage.close();
    },
  );
}
