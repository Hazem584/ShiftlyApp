import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/features/chat/data/api_chat_repository.dart';
import 'package:shiftly/features/chat/data/signed_chat_upload_client.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_reactions.dart';

import 'chat_cache_outbox_test.dart' as fixtures;

void main() {
  test('document contract carries filename through upload and finalizes as DOCUMENT', () async {
    final client = Dio(), requests = <RequestOptions>[];
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          final Object data = options.path.endsWith('/uploads')
              ? {
                  'uploadId': '77777777-7777-4777-8777-777777777777',
                  'bucket': 'chat-media',
                  'path': '${fixtures.workspace}/${fixtures.group}/report.pdf',
                  'uploadToken': 'fixture',
                  'signedUploadUrl': 'https://storage.example/upload',
                  'expiresAt': '2099-01-01T00:00:00.000Z',
                }
              : {
                  'id': fixtures.message(1).id,
                  'groupId': fixtures.group,
                  'type': 'DOCUMENT',
                  'createdAt': '2026-10-30T10:00:00Z',
                  'clientMessageId': '77777777-7777-4777-8777-777777777777',
                  'sender': {'membershipId': fixtures.membership},
                  'attachment': {
                    'id': '77777777-7777-4777-8777-777777777777',
                    'category': 'DOCUMENT',
                    'mimeType': 'application/pdf',
                    'sizeBytes': 14,
                    'fileName': 'report.pdf',
                  },
                };
          handler.resolve(Response(requestOptions: options, data: data));
        },
      ),
    );
    final repo = ApiChatRepository(client, storageUploader: NoUpload());
    final authorization = await repo.initiateUpload(
      fixtures.workspace,
      fixtures.group,
      type: 'DOCUMENT',
      mimeType: 'application/pdf',
      sizeBytes: 14,
      fileName: 'report.pdf',
    );
    expect((requests.single.data as Map)['fileName'], 'report.pdf');
    final message = await repo.finalizeUpload(
      fixtures.workspace,
      fixtures.group,
      type: 'DOCUMENT',
      uploadId: authorization.uploadId,
      clientMessageId: authorization.uploadId,
    );
    expect(message.attachment?.fileName, 'report.pdf');
    expect((requests.last.data as Map)['type'], 'DOCUMENT');
    client.close();
  });
  test(
    'reaction removal sends an explicit null rather than a toggle',
    () async {
      final client = Dio();
      Object? body;
      client.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            body = options.data;
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'id': fixtures.message(1).id,
                  'groupId': fixtures.group,
                  'type': 'TEXT',
                  'text': 'Hello',
                  'createdAt': '2026-10-30T10:00:00Z',
                  'revision': 3,
                  'sender': {'membershipId': fixtures.membership},
                  'reactions': [],
                },
              ),
            );
          },
        ),
      );
      final message =
          await ApiChatRepository(
            client,
            storageUploader: NoUpload(),
          ).setReaction(
            fixtures.workspace,
            fixtures.group,
            fixtures.message(1).id,
            emoji: null,
          );
      expect(body, {'emoji': null});
      expect(message.reactions, isEmpty);
      expect(message.revision, 3);
      client.close();
    },
  );
  testWidgets(
    'reaction chips show counts and remove only the current members reaction',
    (tester) async {
      String? selected = 'unset';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatReactions(
              membershipId: fixtures.membership,
              reactions: const [
                ChatReaction(emoji: '❤️', membershipId: fixtures.membership),
                ChatReaction(emoji: '❤️', membershipId: fixtures.user),
                ChatReaction(emoji: '👍', membershipId: fixtures.user),
              ],
              onReact: (emoji) => selected = emoji,
            ),
          ),
        ),
      );
      expect(find.text('❤️ 2'), findsOneWidget);
      expect(find.text('👍 1'), findsOneWidget);
      await tester.tap(find.text('❤️ 2'));
      expect(selected, isNull);
      await tester.tap(find.text('👍 1'));
      expect(selected, '👍');
      expect(tester.takeException(), isNull);
    },
  );
}

class NoUpload implements ChatStorageUploader {
  @override
  Future<void> upload({
    required String bucket,
    required String path,
    required String uploadToken,
    required Uint8List bytes,
    required String mimeType,
    required bool upsert,
  }) async => throw StateError('No upload expected in HTTP contract test');
}
