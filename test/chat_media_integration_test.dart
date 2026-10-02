import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/chat/data/api_chat_repository.dart';
import 'package:shiftly/features/chat/data/chat_media_validation.dart';
import 'package:shiftly/features/chat/data/chat_models.dart';
import 'package:shiftly/features/chat/data/chat_realtime.dart';
import 'package:shiftly/features/chat/data/chat_repository.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';

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
        final signed = Dio();
        final requests = <RequestOptions>[];
        final signedRequests = <RequestOptions>[];
        backend.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add(options);
              final path = options.path;
              Object? data;
              if (path.endsWith('/uploads') && options.method == 'POST') {
                data = {
                  'uploadId': uploadId,
                  'signedUploadUrl':
                      'https://storage.example/signed?token=secret',
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
        signed.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              signedRequests.add(options);
              handler.resolve(Response<void>(requestOptions: options));
            },
          ),
        );
        final repository = ApiChatRepository(
          backend,
          signedUploadClient: signed,
        );
        final authorization = await repository.initiateUpload(
          workspace,
          groupId,
          type: 'IMAGE',
          mimeType: 'image/png',
          sizeBytes: 8,
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
          'sizeBytes': 8,
        });
        expect(signedRequests.single.method, 'PUT');
        expect(
          signedRequests.single.headers[Headers.contentTypeHeader],
          'image/png',
        );
        expect(signedRequests.single.headers['x-upsert'], 'false');
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
            Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 13, 10, 26, 10]),
          ),
          'image/png',
        );
        expect(
          ChatMediaValidation.imageMime(Uint8List.fromList([1, 2, 3])),
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
        final id = await cubit.sendMedia(
          type: 'IMAGE',
          mimeType: 'image/jpeg',
          bytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]),
        );
        await _waitFor(
          () => cubit.state.pending.single.status == ChatUploadState.failed,
        );
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
  });
}

Future<void> _waitFor(bool Function() condition) async {
  for (var index = 0; index < 100 && !condition(); index++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(condition(), isTrue);
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
  int cancelled = 0;
  int authorizations = 0;
  final clientIds = <String>[];

  @override
  Future<ChatMessagePage> listMessages(
    String workspaceId,
    String groupId, {
    String? cursor,
    int limit = 30,
  }) async => const ChatMessagePage(messages: []);

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
    return ChatUploadAuthorization(
      uploadId: uploadId,
      signedUploadUrl: Uri.parse('https://storage.example/signed'),
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
  }) async {
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
    final json = _message(type)..['clientMessageId'] = clientMessageId;
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
