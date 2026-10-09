import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/chat/data/signed_chat_upload_client.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/entities/chat_upload_cancellation.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';

final _bytes = Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]);

void main() {
  group('signed chat upload client', () {
    test(
      'passes exact authorization, bytes and file options to Storage',
      () async {
        final uploader = _Uploader();
        final progress = <(int, int)>[];
        await SignedChatUploadClient(uploader).upload(
          authorization: _authorization(),
          bytes: _bytes,
          mimeType: 'image/jpeg',
          onProgress: (sent, total) => progress.add((sent, total)),
        );

        expect(uploader.bucket, 'chat-media');
        expect(uploader.path, 'workspace/group/file.jpg');
        expect(uploader.uploadToken, 'private-token');
        expect(uploader.bytes, same(_bytes));
        expect(uploader.mimeType, 'image/jpeg');
        expect(uploader.upsert, isFalse);
        expect(progress, [(_bytes.length, _bytes.length)]);
      },
    );

    test('passes voice MIME and exact voice bytes', () async {
      final voice = Uint8List.fromList([0, 0, 0, 20, 0x66, 0x74, 0x79, 0x70]);
      final uploader = _Uploader();
      await SignedChatUploadClient(uploader).upload(
        authorization: _authorization(
          path: 'workspace/group/file.m4a',
          mimeType: 'audio/mp4',
          size: voice.length,
        ),
        bytes: voice,
        mimeType: 'audio/mp4',
      );
      expect(uploader.bytes, same(voice));
      expect(uploader.mimeType, 'audio/mp4');
      expect(uploader.upsert, isFalse);
    });

    test('reports completion only after Storage succeeds', () async {
      final gate = Completer<void>();
      final uploader = _Uploader(gate: gate);
      final progress = <(int, int)>[];
      final future = SignedChatUploadClient(uploader).upload(
        authorization: _authorization(),
        bytes: _bytes,
        mimeType: 'image/jpeg',
        onProgress: (sent, total) => progress.add((sent, total)),
      );
      await Future<void>.delayed(Duration.zero);
      expect(progress, isEmpty);
      gate.complete();
      await future;
      expect(progress, [(_bytes.length, _bytes.length)]);
    });

    test(
      'maps provider failures without exposing authorization secrets',
      () async {
        final error = await _capture(
          SignedChatUploadClient(
            _Uploader(error: StateError('provider secret')),
          ).upload(
            authorization: _authorization(),
            bytes: _bytes,
            mimeType: 'image/jpeg',
          ),
        ) as ApiException;
        expect(error.code, 'CHAT_MEDIA_STORAGE_UPLOAD_FAILED');
        expect(error.toString(), isNot(contains('private-token')));
        expect(error.toString(), isNot(contains('workspace/group/file.jpg')));
        expect(error.toString(), isNot(contains('provider secret')));
      },
    );

    test('rejects changed size or MIME before invoking Storage', () async {
      for (final invocation in [
        () => SignedChatUploadClient(_Uploader()).upload(
          authorization: _authorization(),
          bytes: Uint8List.fromList([1]),
          mimeType: 'image/jpeg',
        ),
        () => SignedChatUploadClient(_Uploader()).upload(
          authorization: _authorization(),
          bytes: _bytes,
          mimeType: 'image/png',
        ),
      ]) {
        final error = await _capture(invocation()) as ApiException;
        expect(error.code, 'CHAT_MEDIA_UPLOAD_METADATA_CHANGED');
      }
    });

    test('honors cancellation before contacting Storage', () async {
      final cancellation = ChatUploadCancellation()..cancel();
      final uploader = _Uploader();
      final error = await _capture(
        SignedChatUploadClient(uploader).upload(
          authorization: _authorization(),
          bytes: _bytes,
          mimeType: 'image/jpeg',
          cancellation: cancellation,
        ),
      ) as ApiException;
      expect(error.kind, FailureKind.cancelled);
      expect(uploader.calls, 0);
    });

    test('authorization diagnostics do not expose path or token', () {
      final authorization = _authorization();
      expect(authorization.toString(), isNot(contains('private-token')));
      expect(
        authorization.toString(),
        isNot(contains('workspace/group/file.jpg')),
      );
    });
  });
}

ChatUploadAuthorization _authorization({
  String path = 'workspace/group/file.jpg',
  String mimeType = 'image/jpeg',
  int? size,
}) => ChatUploadAuthorization(
  uploadId: '44444444-4444-4444-8444-444444444444',
  bucket: 'chat-media',
  path: path,
  uploadToken: 'private-token',
  expiresAt: DateTime.utc(2099),
  expectedMimeType: mimeType,
  expectedSizeBytes: size ?? _bytes.length,
);

Future<Object> _capture(Future<void> future) async {
  try {
    await future;
  } catch (error) {
    return error;
  }
  throw StateError('Expected operation to fail');
}

class _Uploader implements ChatStorageUploader {
  _Uploader({this.gate, this.error});

  final Completer<void>? gate;
  final Object? error;
  int calls = 0;
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
    calls++;
    this.bucket = bucket;
    this.path = path;
    this.uploadToken = uploadToken;
    this.bytes = bytes;
    this.mimeType = mimeType;
    this.upsert = upsert;
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
  }
}
