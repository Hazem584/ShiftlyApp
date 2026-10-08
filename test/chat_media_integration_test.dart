import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/chat/data/api_chat_repository.dart';
import 'package:shiftly/features/chat/data/chat_media_validation.dart';
import 'package:shiftly/features/chat/data/chat_models.dart';
import 'package:shiftly/features/chat/data/chat_realtime.dart';
import 'package:shiftly/features/chat/data/chat_repository.dart';
import 'package:shiftly/features/chat/data/signed_chat_upload_client.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/screens/chat_screen.dart';

const workspace = '11111111-1111-4111-8111-111111111111';
const groupId = '22222222-2222-4222-8222-222222222222';
const membership = '33333333-3333-4333-8333-333333333333';
const uploadId = '44444444-4444-4444-8444-444444444444';

void main() {
  group('chat media repository contract', () {
    test(
      'uses exact initiate, signed PUT, finalize, cancel and media paths',
      () async {
        final backend = Dio();
        final requests = <RequestOptions>[];
        final storage = _StorageUploader();
        backend.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add(options);
              final path = options.path;
              Object? data;
              if (path.endsWith('/uploads') && options.method == 'POST') {
                data = {
                  'uploadId': uploadId,
                  'bucket': 'chat-media',
                  'path': '$workspace/$groupId/file.png',
                  'signedUploadUrl': 'https://storage.example/storage/v1/object/upload/sign/chat-media/safe',
                  'uploadToken': 'secret',
                  'expiresAt': '2099-01-01T00:00:00.000Z',
                };
              } else if (path.endsWith('/messages') &&
                  options.method == 'POST') {
                data = _message('IMAGE');
              } else if (path.endsWith('/media-url')) {
                data = {
                  'url': 'https://storage.example/download?token=secret',
                  'expiresAt': '2099-01-01T00:00:00.000Z',
                };
              } else {
                data = {'cancelled': true};
              }
              handler.resolve(Response(requestOptions: options, data: data));
            },
          ),
        );
        final repository = ApiChatRepository(backend, storageUploader: storage);
        final authorization = await repository.initiateUpload(
          workspace,
          groupId,
          type: 'IMAGE',
          mimeType: 'image/png',
          sizeBytes: 3,
        );
        await repository.uploadSigned(
          authorization,
          Uint8List.fromList([1, 2, 3]),
          'image/png',
        );
        await repository.finalizeUpload(
          workspace,
          groupId,
          type: 'IMAGE',
          uploadId: uploadId,
          clientMessageId: '55555555-5555-4555-8555-555555555555',
        );
        await repository.cancelUpload(workspace, groupId, uploadId);
        await repository.mediaUrl(
          workspace,
          groupId,
          '66666666-6666-4666-8666-666666666666',
        );

        expect(requests[0].method, 'POST');
        expect(
          requests[0].path,
          '/workspaces/$workspace/chat/groups/$groupId/uploads',
        );
        expect(requests[0].data, {
          'type': 'IMAGE',
          'mimeType': 'image/png',
          'sizeBytes': 3,
        });
        expect(storage.bucket, 'chat-media');
        expect(storage.path, '$workspace/$groupId/file.png');
        expect(storage.uploadToken, 'secret');
        expect(storage.bytes, Uint8List.fromList([1, 2, 3]));
        expect(storage.mimeType, 'image/png');
        expect(storage.upsert, isFalse);
        expect(requests[1].data, {
          'type': 'IMAGE',
          'uploadId': uploadId,
          'clientMessageId': '55555555-5555-4555-8555-555555555555',
        });
        expect(requests[2].method, 'DELETE');
        expect(
          requests[2].path,
          '/workspaces/$workspace/chat/groups/$groupId/uploads/$uploadId',
        );
        expect(
          requests[3].path,
          contains('/messages/66666666-6666-4666-8666-666666666666/media-url'),
        );
        expect(authorization.toString(), isNot(contains('secret')));
      },
    );

    test(
      'uses exact IMAGE and VOICE initiate and finalization payloads',
      () async {
        for (final type in ['IMAGE', 'VOICE']) {
          final requests = <RequestOptions>[];
          final dio = Dio()
            ..interceptors.add(
              InterceptorsWrapper(
                onRequest: (options, handler) {
                  requests.add(options);
                  handler.resolve(
                    Response<Object?>(
                      requestOptions: options,
                      data: options.path.endsWith('/uploads')
                          ? {
                              'uploadId': uploadId,
                              'bucket': 'chat-media',
                              'path': '$workspace/$groupId/file',
                              'signedUploadUrl': 'https://storage.example/storage/v1/object/upload/sign/chat-media/safe?token=secret',
                              'uploadToken': 'secret',
                              'expiresAt': '2099-01-01T00:00:00.000Z',
                            }
                          : _message(type),
                    ),
                  );
                },
              ),
            );
          final repository = ApiChatRepository(
            dio,
            storageUploader: _StorageUploader(),
          );
          await repository.initiateUpload(
            workspace,
            groupId,
            type: type,
            mimeType: type == 'IMAGE' ? 'image/jpeg' : 'audio/mp4',
            sizeBytes: 100,
            durationMs: type == 'VOICE' ? 45000 : null,
          );
          await repository.finalizeUpload(
            workspace,
            groupId,
            type: type,
            uploadId: uploadId,
            clientMessageId: '55555555-5555-4555-8555-555555555555',
          );
          expect(
            requests[0].data,
            type == 'IMAGE'
                ? {'type': 'IMAGE', 'mimeType': 'image/jpeg', 'sizeBytes': 100}
                : {
                    'type': 'VOICE',
                    'mimeType': 'audio/mp4',
                    'sizeBytes': 100,
                    'durationMs': 45000,
                  },
          );
          expect(requests[1].data, {
            'type': type,
            'uploadId': uploadId,
            'clientMessageId': '55555555-5555-4555-8555-555555555555',
          });
        }
      },
    );

    test('rejects invalid finalization UUIDs before a request', () async {
      final requests = <RequestOptions>[];
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add(options);
              handler.resolve(Response<Object?>(requestOptions: options));
            },
          ),
        );
      final repository = ApiChatRepository(
        dio,
        storageUploader: _StorageUploader(),
      );
      await expectLater(
        repository.finalizeUpload(
          workspace,
          groupId,
          type: 'IMAGE',
          uploadId: 'not-a-uuid',
          clientMessageId: 'also-invalid',
        ),
        throwsA(isA<ApiException>()),
      );
      expect(requests, isEmpty);
    });

    test('parses canonical image, voice and location messages', () {
      final image = ChatMessage.fromJson(_message('IMAGE'));
      final voice = ChatMessage.fromJson(_message('VOICE'));
      final location = ChatMessage.fromJson(_message('LOCATION'));
      expect(image.attachment?.mimeType, 'image/jpeg');
      expect(voice.attachment?.durationMs, 45000);
      expect(location.location?.latitude, 29.123456);
      expect(location.location?.isValid, isTrue);
    });
  });

  group('validation and upload state', () {
    test(
      'recognizes image signatures and rejects spoofed or oversized input',
      () {
        expect(
          ChatMediaValidation.imageMime(
            Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]),
          ),
          'image/jpeg',
        );
        expect(ChatMediaValidation.imageMime(_pngBytes()), 'image/png');
        expect(ChatMediaValidation.imageMime(_webpBytes()), 'image/webp');
        expect(
          ChatMediaValidation.imageMime(Uint8List.fromList([1, 2, 3])),
          isNull,
        );
        expect(
          ChatMediaValidation.imageMime(
            Uint8List.fromList([0xff, 0xd8, 0xff, 0x00]),
          ),
          isNull,
        );
        expect(
          ChatMediaValidation.imageMime(
            Uint8List(ChatMediaValidation.imageMaxBytes + 1),
          ),
          isNull,
        );
        expect(ChatMediaValidation.imageMaxBytes, 5 * 1024 * 1024);
      },
    );

    test('enforces voice signature, nonzero duration and backend maximum', () {
      final mp4 = Uint8List.fromList([
        0,
        0,
        0,
        20,
        0x66,
        0x74,
        0x79,
        0x70,
        0x4d,
        0x34,
        0x41,
        0x20,
      ]);
      expect(
        ChatMediaValidation.validVoice(
          bytes: mp4,
          mimeType: 'audio/mp4',
          durationMs: 1,
        ),
        isTrue,
      );
      expect(
        ChatMediaValidation.validVoice(
          bytes: mp4,
          mimeType: 'audio/mp4',
          durationMs: 0,
        ),
        isFalse,
      );
      final supported = <String, Uint8List>{
        'audio/aac': Uint8List.fromList([0xff, 0xf1]),
        'audio/mpeg': Uint8List.fromList('ID3safe'.codeUnits),
        'audio/ogg': Uint8List.fromList('OggSsafe'.codeUnits),
        'audio/webm': Uint8List.fromList([0x1a, 0x45, 0xdf, 0xa3]),
      };
      for (final entry in supported.entries) {
        expect(
          ChatMediaValidation.validVoice(
            bytes: entry.value,
            mimeType: entry.key,
            durationMs: 1000,
          ),
          isTrue,
          reason: entry.key,
        );
      }
      expect(
        ChatMediaValidation.validVoice(
          bytes: mp4,
          mimeType: 'audio/mp4',
          durationMs: 600001,
        ),
        isFalse,
      );
    });

    test(
      'retry keeps one stable client id and replaces pending canonically',
      () async {
        final repository = _MediaRepository()..uploadFailures = 1;
        final cubit = ChatConversationCubit(repository, const _Realtime())
          ..bind(
            const FeatureSessionScope(
              userId: '77777777-7777-4777-8777-777777777777',
              workspaceId: workspace,
              membershipId: membership,
              timezone: 'Etc/UTC',
              role: WorkspaceRole.employee,
            ),
            groupId,
          );
        final id = await cubit.sendImage(
          Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]),
        );
        await _waitFor(
          () => const [
            ChatUploadState.failed,
            ChatUploadState.uncertain,
          ].contains(cubit.state.pending.single.status),
        );
        expect(repository.clientIds, isEmpty);
        await cubit.retryMedia(id!);
        await _waitFor(
          () => cubit.state.pending.isEmpty && cubit.state.messages.isNotEmpty,
        );
        expect(repository.clientIds, [id]);
        expect(cubit.state.messages.single.clientMessageId, id);
        expect(repository.cancelled, 1);
        await cubit.close();
      },
    );

    test(
      'ambiguous finalization failure retries the same upload and client id',
      () async {
        final repository = _MediaRepository()..finalizeFailures = 1;
        final cubit = ChatConversationCubit(repository, const _Realtime())
          ..bind(_scope, groupId);
        final id = await cubit.sendImage(
          Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]),
        );
        await _waitFor(
          () => const [
            ChatUploadState.failed,
            ChatUploadState.uncertain,
          ].contains(cubit.state.pending.single.status),
        );
        expect(repository.authorizations, 1);
        expect(repository.uploads, 1);
        expect(repository.cancelled, 0);
        await cubit.retryMedia(id!);
        await _waitFor(() => cubit.state.pending.isEmpty);
        expect(repository.authorizations, 1);
        expect(repository.uploads, 1);
        expect(repository.clientIds, [id, id]);
        await cubit.close();
      },
    );

    test('canonical success remains when a later refresh fails', () async {
      final repository = _MediaRepository();
      final cubit = ChatConversationCubit(repository, const _Realtime())
        ..bind(_scope, groupId);
      await cubit.sendImage(Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]));
      await _waitFor(() => cubit.state.messages.isNotEmpty);
      repository.listFailures = 1;
      await cubit.load(refresh: true);
      expect(cubit.state.messages, hasLength(1));
      expect(cubit.state.pending, isEmpty);
      await cubit.close();
    });

    test('voice followed by image keeps every job field isolated', () async {
      final gate = Completer<void>();
      final repository = _MediaRepository()..uploadGate = gate;
      final cubit = ChatConversationCubit(repository, const _Realtime())
        ..bind(_scope, groupId);
      final voice = _voiceBytes();
      final image = Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]);
      final voiceId = await cubit.sendVoice(
        bytes: voice,
        mimeType: 'audio/mp4',
        durationMs: 1234,
      );
      final imageId = await cubit.sendImage(image);
      voice[0] = 99;
      image[0] = 99;
      await _waitFor(() => repository.uploads == 1);

      expect(voiceId, isNot(imageId));
      expect(repository.initiatedTypes, ['VOICE']);
      expect(repository.initiatedMimes, ['audio/mp4']);
      expect(repository.initiatedDurations, [1234]);
      expect(repository.uploadedBytes[0], _voiceBytes());

      expect(cubit.state.pending.map((pending) => pending.mediaType), [
        PendingChatMediaType.voice,
        PendingChatMediaType.image,
      ]);
      expect(cubit.state.pending.first.durationMs, 1234);
      expect(cubit.state.pending.last.durationMs, isNull);
      expect(repository.finalizedTypes, isEmpty);

      gate.complete();
      await _waitFor(() => cubit.state.pending.isEmpty);
      expect(repository.finalizedTypes, ['VOICE', 'IMAGE']);
      expect(repository.initiatedMimes, ['audio/mp4', 'image/jpeg']);
      expect(repository.uploadedBytes[1], [0xff, 0xd8, 0xff, 0xd9]);
      await cubit.close();
    });

    test(
      'image followed by voice keeps type, bytes, MIME and duration isolated',
      () async {
        final gate = Completer<void>();
        final repository = _MediaRepository()..uploadGate = gate;
        final cubit = ChatConversationCubit(repository, const _Realtime())
          ..bind(_scope, groupId);
        await cubit.sendImage(Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]));
        await cubit.sendVoice(
          bytes: _voiceBytes(),
          mimeType: 'audio/mp4',
          durationMs: 987,
        );
        await _waitFor(() => repository.uploads == 1);
        expect(repository.initiatedTypes, ['IMAGE']);
        expect(repository.initiatedDurations, [null]);
        expect(repository.uploadedMimes, ['image/jpeg']);
        gate.complete();
        await _waitFor(() => cubit.state.pending.isEmpty);
        expect(repository.initiatedTypes, ['IMAGE', 'VOICE']);
        expect(repository.initiatedDurations, [null, 987]);
        expect(repository.uploadedMimes, ['image/jpeg', 'audio/mp4']);
        await cubit.close();
      },
    );

    test('object-invalid failure retains image type and request ID', () async {
      final repository = _MediaRepository()
        ..finalizeError = const ApiException(
          statusCode: 400,
          code: 'CHAT_MEDIA_OBJECT_INVALID',
          requestId: 'req-media-1',
          message: 'The uploaded media did not pass verification.',
        );
      final cubit = ChatConversationCubit(repository, const _Realtime())
        ..bind(_scope, groupId);
      await cubit.sendImage(Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]));
      await _waitFor(
        () => const [
          ChatUploadState.failed,
          ChatUploadState.uncertain,
        ].contains(cubit.state.pending.single.status),
      );
      final pending = cubit.state.pending.single;
      expect(pending.mediaType, PendingChatMediaType.image);
      expect(pending.failure?.requestId, 'req-media-1');
      expect(repository.cancelled, 1);
      await cubit.close();
    });

    test('cancellation failure does not replace the upload failure', () async {
      final repository = _MediaRepository()
        ..uploadFailures = 1
        ..cancelFails = true;
      final cubit = ChatConversationCubit(repository, const _Realtime())
        ..bind(_scope, groupId);
      await cubit.sendImage(Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]));
      await _waitFor(
        () => const [
          ChatUploadState.failed,
          ChatUploadState.uncertain,
        ].contains(cubit.state.pending.single.status),
      );
      expect(
        cubit.state.pending.single.failure?.message,
        'Unable to send media.',
      );
      expect(repository.finalizedTypes, isEmpty);
      await cubit.close();
    });

    test(
      'mismatched canonical response does not replace another job',
      () async {
        final repository = _MediaRepository()
          ..canonicalClientId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
        final cubit = ChatConversationCubit(repository, const _Realtime())
          ..bind(_scope, groupId);
        await cubit.sendImage(Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]));
        await _waitFor(
          () => const [
            ChatUploadState.failed,
            ChatUploadState.uncertain,
          ].contains(cubit.state.pending.single.status),
        );
        expect(cubit.state.messages, isEmpty);
        expect(
          cubit.state.pending.single.mediaType,
          PendingChatMediaType.image,
        );
        await cubit.close();
      },
    );

    testWidgets('image pending UI never displays Voice message', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendingMediaBubble(
              pending: const PendingChatMessage(
                clientMessageId: 'image-id',
                mediaType: PendingChatMediaType.image,
                status: ChatUploadState.finalizing,
              ),
              onRetry: (_) async {},
              onCancel: (_) async {},
            ),
          ),
        ),
      );
      expect(find.text('Image'), findsOneWidget);
      expect(find.text('Voice message'), findsNothing);
    });

    testWidgets('voice pending UI never displays as an image', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendingMediaBubble(
              pending: const PendingChatMessage(
                clientMessageId: 'voice-id',
                mediaType: PendingChatMediaType.voice,
                status: ChatUploadState.uploading,
                durationMs: 1500,
              ),
              onRetry: (_) async {},
              onCancel: (_) async {},
            ),
          ),
        ),
      );
      expect(find.text('Voice message'), findsOneWidget);
      expect(find.text('Image'), findsNothing);
      expect(find.byType(Image), findsNothing);
    });
  });

  test('strictly validates upload authorization fields', () {
    Map<String, Object?> valid() => {
      'uploadId': uploadId,
      'bucket': 'chat-media',
      'path': '$workspace/$groupId/file.jpg',
      'signedUploadUrl': 'https://storage.example/signed',
      'uploadToken': 'secret',
      'expiresAt': '2099-01-01T00:00:00.000Z',
    };
    expect(ChatUploadAuthorization.fromJson(valid()).bucket, 'chat-media');
    for (final invalid in [
      {...valid(), 'bucket': 'other'},
      {...valid(), 'path': '../file.jpg'},
      {...valid(), 'path': '%2e%2e/file.jpg'},
      {...valid(), 'uploadToken': ''},
      {...valid(), 'expiresAt': '2020-01-01T00:00:00.000Z'},
    ]) {
      expect(
        () => ChatUploadAuthorization.fromJson(invalid),
        throwsFormatException,
      );
    }
  });
}

const _scope = FeatureSessionScope(
  userId: '77777777-7777-4777-8777-777777777777',
  workspaceId: workspace,
  membershipId: membership,
  timezone: 'Etc/UTC',
  role: WorkspaceRole.employee,
);

Future<void> _waitFor(bool Function() condition) async {
  for (var index = 0; index < 100 && !condition(); index++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(condition(), isTrue);
}

Uint8List _voiceBytes() => Uint8List.fromList([
  0,
  0,
  0,
  20,
  0x66,
  0x74,
  0x79,
  0x70,
  0x4d,
  0x34,
  0x41,
  0x20,
]);

Uint8List _pngBytes() {
  final bytes = Uint8List(45);
  bytes.setAll(0, [0x89, 0x50, 0x4e, 0x47, 13, 10, 26, 10]);
  bytes.setAll(12, 'IHDR'.codeUnits);
  bytes.setAll(33, [
    0,
    0,
    0,
    0,
    0x49,
    0x45,
    0x4e,
    0x44,
    0xae,
    0x42,
    0x60,
    0x82,
  ]);
  return bytes;
}

Uint8List _webpBytes() {
  final bytes = Uint8List(20);
  bytes.setAll(0, 'RIFF'.codeUnits);
  bytes.setAll(4, [12, 0, 0, 0]);
  bytes.setAll(8, 'WEBP'.codeUnits);
  bytes.setAll(12, 'VP8 '.codeUnits);
  return bytes;
}

Map<String, Object?> _message(String type) => {
  'id': '66666666-6666-4666-8666-666666666666',
  'groupId': groupId,
  'type': type,
  'text': type == 'TEXT' ? 'Hello' : null,
  'sender': {'membershipId': membership, 'fullName': 'Member'},
  'clientMessageId': '55555555-5555-4555-8555-555555555555',
  'replyToMessageId': null,
  'createdAt': '2026-10-03T00:00:00.000Z',
  'attachment': type == 'IMAGE' || type == 'VOICE'
      ? {
          'id': uploadId,
          'category': type,
          'mimeType': type == 'IMAGE' ? 'image/jpeg' : 'audio/mp4',
          'sizeBytes': 100,
          'durationMs': type == 'VOICE' ? 45000 : null,
        }
      : null,
  'location': type == 'LOCATION'
      ? {
          'latitude': 29.123456,
          'longitude': 31.456789,
          'label': 'Warehouse',
          'address': null,
        }
      : null,
};

class _MediaRepository extends ChatRepository {
  int uploadFailures = 0;
  int finalizeFailures = 0;
  int listFailures = 0;
  int cancelled = 0;
  int authorizations = 0;
  int uploads = 0;
  final clientIds = <String>[];
  final initiatedTypes = <String>[];
  final initiatedMimes = <String>[];
  final initiatedSizes = <int>[];
  final initiatedDurations = <int?>[];
  final uploadedBytes = <Uint8List>[];
  final uploadedMimes = <String>[];
  final finalizedTypes = <String>[];
  Completer<void>? uploadGate;
  ApiException? finalizeError;
  bool cancelFails = false;
  String? canonicalClientId;

  @override
  Future<ChatMessagePage> listMessages(
    String workspaceId,
    String groupId, {
    String? cursor,
    int limit = 30,
  }) async {
    if (listFailures-- > 0) {
      throw const ApiException(message: 'Safe refresh failure');
    }
    return const ChatMessagePage(messages: []);
  }

  @override
  Future<ChatUploadAuthorization> initiateUpload(
    String workspaceId,
    String groupId, {
    required String type,
    required String mimeType,
    required int sizeBytes,
    int? durationMs,
  }) async {
    authorizations++;
    initiatedTypes.add(type);
    initiatedMimes.add(mimeType);
    initiatedSizes.add(sizeBytes);
    initiatedDurations.add(durationMs);
    return ChatUploadAuthorization(
      uploadId: uploadId,
      bucket: 'chat-media',
      path: '$workspaceId/$groupId/file',
      uploadToken: 'not-logged',
      expiresAt: DateTime.utc(2099),
    );
  }

  @override
  Future<void> uploadSigned(
    ChatUploadAuthorization authorization,
    Uint8List bytes,
    String mimeType, {
    void Function(int sent, int total)? onProgress,
    ChatUploadCancellation? cancellation,
  }) async {
    uploads++;
    uploadedBytes.add(Uint8List.fromList(bytes));
    uploadedMimes.add(mimeType);
    if (uploadGate != null) await uploadGate!.future;
    onProgress?.call(bytes.length, bytes.length);
    if (uploadFailures-- > 0) {
      throw DioException(requestOptions: RequestOptions());
    }
  }

  @override
  Future<void> cancelUpload(
    String workspaceId,
    String groupId,
    String uploadId,
  ) async {
    cancelled++;
    if (cancelFails) throw const ApiException(message: 'Safe cancel failure');
  }

  @override
  Future<ChatMessage> finalizeUpload(
    String workspaceId,
    String groupId, {
    required String type,
    required String uploadId,
    required String clientMessageId,
  }) async {
    clientIds.add(clientMessageId);
    finalizedTypes.add(type);
    if (finalizeError != null) throw finalizeError!;
    if (finalizeFailures-- > 0) {
      throw const ApiException(message: 'Safe ambiguous failure');
    }
    final json = _message(type)
      ..['clientMessageId'] = canonicalClientId ?? clientMessageId;
    return ChatMessage.fromJson(json);
  }

  @override
  Future<void> markRead(
    String workspaceId,
    String groupId,
    String messageId,
  ) async {}

  @override
  Future<List<ChatGroup>> listGroups(String workspaceId) =>
      throw UnimplementedError();
  @override
  Future<ChatGroup> getGroup(String workspaceId, String groupId) =>
      throw UnimplementedError();
  @override
  Future<ChatGroup> createGroup(
    String workspaceId, {
    required String name,
    String? description,
    required List<String> memberMembershipIds,
  }) => throw UnimplementedError();
  @override
  Future<void> updateGroup(
    String workspaceId,
    String groupId, {
    required String name,
    String? description,
  }) => throw UnimplementedError();
  @override
  Future<void> archiveGroup(String workspaceId, String groupId) =>
      throw UnimplementedError();
  @override
  Future<void> addMembers(
    String workspaceId,
    String groupId,
    List<String> membershipIds,
  ) => throw UnimplementedError();
  @override
  Future<void> removeMember(
    String workspaceId,
    String groupId,
    String membershipId,
  ) => throw UnimplementedError();
  @override
  Future<ChatMessage> sendMessage(
    String workspaceId,
    String groupId, {
    required String text,
    required String clientMessageId,
    String? replyToMessageId,
  }) => throw UnimplementedError();
  @override
  Future<int> unreadCount(String workspaceId) => throw UnimplementedError();
}

class _Realtime implements ChatRealtime {
  const _Realtime();
  @override
  ChatRealtimeSubscription subscribeToGroup(
    String groupId,
    void Function() onInsert,
  ) => const _Subscription();
}

class _Subscription implements ChatRealtimeSubscription {
  const _Subscription();
  @override
  Future<void> cancel() async {}
}

class _StorageUploader implements ChatStorageUploader {
  String? bucket;
  String? path;
  String? uploadToken;
  Uint8List? bytes;
  String? mimeType;
  bool? upsert;

  @override
  Future<void> upload({
    required String bucket,
    required String path,
    required String uploadToken,
    required Uint8List bytes,
    required String mimeType,
    required bool upsert,
  }) async {
    this.bucket = bucket;
    this.path = path;
    this.uploadToken = uploadToken;
    this.bytes = bytes;
    this.mimeType = mimeType;
    this.upsert = upsert;
  }
}
