import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/chat/data/chat_models.dart';
import 'package:shiftly/features/chat/data/chat_repository.dart';
import 'package:shiftly/features/chat/data/signed_chat_upload_client.dart';

const _origin = 'https://project.supabase.co';
const _path =
    '/storage/v1/object/upload/sign/chat-media/workspace/group/file.jpg';
final _bytes = Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]);

void main() {
  group('signed chat upload client', () {
    test(
      'appends a missing token once and preserves existing query values',
      () async {
        final adapter = _UploadAdapter();
        final progress = <(int, int)>[];
        await _client(adapter).upload(
          authorization: _authorization('$_origin$_path?download=1'),
          bytes: _bytes,
          mimeType: 'image/jpeg',
          onProgress: (sent, total) => progress.add((sent, total)),
        );

        final request = adapter.request!;
        expect(request.uri.queryParameters['download'], '1');
        expect(request.uri.queryParametersAll['token'], ['private-token']);
        expect(adapter.bytes, _bytes);
        expect(request.contentType, 'image/jpeg');
        expect(
          request.headers[Headers.contentLengthHeader],
          _bytes.length.toString(),
        );
        expect(request.headers['x-upsert'], 'false');
        expect(request.headers.containsKey('Authorization'), isFalse);
        expect(request.followRedirects, isFalse);
        expect(progress, isNotEmpty);
        expect(progress.last, (_bytes.length, _bytes.length));
      },
    );

    test(
      'keeps an existing exact token without duplication or replacement',
      () async {
        final adapter = _UploadAdapter();
        await _client(adapter).upload(
          authorization: _authorization(
            '$_origin$_path?token=private-token&download=1',
          ),
          bytes: _bytes,
          mimeType: 'image/jpeg',
        );
        expect(adapter.request!.uri.queryParametersAll['token'], [
          'private-token',
        ]);
        expect(adapter.request!.uri.queryParameters['download'], '1');
      },
    );

    test('rejects duplicate or mismatched URL tokens', () async {
      for (final url in [
        '$_origin$_path?token=private-token&token=private-token',
        '$_origin$_path?token=different-token',
      ]) {
        final error = await _capture(
          _client(_UploadAdapter()).upload(
            authorization: _authorization(url),
            bytes: _bytes,
            mimeType: 'image/jpeg',
          ),
        );
        expect(
          (error as ApiException).code,
          'CHAT_MEDIA_UPLOAD_DESTINATION_INVALID',
        );
      }
    });

    test(
      'rejects HTTP, foreign origins, ports, userinfo, fragments, and paths',
      () async {
        final invalid = [
          'http://project.supabase.co$_path',
          'https://other.supabase.co$_path',
          'https://project.supabase.co:444$_path',
          'https://user@project.supabase.co$_path',
          '$_origin$_path#fragment',
          '$_origin/storage/v1/object/public/chat-media/file.jpg',
        ];
        for (final url in invalid) {
          final adapter = _UploadAdapter();
          final error = await _capture(
            _client(adapter).upload(
              authorization: _authorization(url),
              bytes: _bytes,
              mimeType: 'image/jpeg',
            ),
          );
          expect(
            (error as ApiException).code,
            'CHAT_MEDIA_UPLOAD_DESTINATION_INVALID',
          );
          expect(adapter.request, isNull);
        }
      },
    );

    test(
      'rejects redirects and non-2xx responses without exposing response data',
      () async {
        for (final status in [302, 400, 500]) {
          final adapter = _UploadAdapter(
            status: status,
            responseBody: 'private-provider-body',
          );
          final error = await _capture(
            _client(adapter).upload(
              authorization: _authorization('$_origin$_path'),
              bytes: _bytes,
              mimeType: 'image/jpeg',
            ),
          );
          expect(
            (error as ApiException).code,
            'CHAT_MEDIA_STORAGE_UPLOAD_FAILED',
          );
          expect(error.toString(), isNot(contains('private-provider-body')));
          expect(error.toString(), isNot(contains('private-token')));
          expect(error.toString(), isNot(contains(_path)));
        }
      },
    );

    test('maps network and timeout failures safely', () async {
      final cases = <DioExceptionType, FailureKind>{
        DioExceptionType.connectionError: FailureKind.network,
        DioExceptionType.sendTimeout: FailureKind.timeout,
      };
      for (final entry in cases.entries) {
        final error = await _capture(
          _client(_UploadAdapter(errorType: entry.key)).upload(
            authorization: _authorization('$_origin$_path'),
            bytes: _bytes,
            mimeType: 'image/jpeg',
          ),
        ) as ApiException;
        expect(error.kind, entry.value);
        expect(error.toString(), isNot(contains('private-token')));
      }
    });

    test('supports cancellation without leaking the destination', () async {
      final cancellation = ChatUploadCancellation();
      final future = _client(_UploadAdapter(waitForCancellation: true)).upload(
        authorization: _authorization('$_origin$_path'),
        bytes: _bytes,
        mimeType: 'image/jpeg',
        cancellation: cancellation,
      );
      await Future<void>.delayed(Duration.zero);
      cancellation.cancel();
      final error = await _capture(future) as ApiException;
      expect(error.code, 'CHAT_MEDIA_UPLOAD_CANCELLED');
      expect(error.kind, FailureKind.cancelled);
      expect(error.toString(), isNot(contains('private-token')));
    });

    test('rejects changed size or MIME before sending bytes', () async {
      final authorization = _authorization('$_origin$_path');
      for (final invocation in [
        () => _client(_UploadAdapter()).upload(
          authorization: authorization,
          bytes: Uint8List.fromList([1]),
          mimeType: 'image/jpeg',
        ),
        () => _client(_UploadAdapter()).upload(
          authorization: authorization,
          bytes: _bytes,
          mimeType: 'image/png',
        ),
      ]) {
        final error = await _capture(invocation());
        expect(
          (error as ApiException).code,
          'CHAT_MEDIA_UPLOAD_METADATA_CHANGED',
        );
      }
    });

    test(
      'authorization diagnostics and equality do not expose URL or token',
      () {
        final first = _authorization('$_origin$_path?token=private-token');
        final second = _authorization('$_origin$_path?token=another-secret');
        expect(first, second);
        expect(first.toString(), isNot(contains('private-token')));
        expect(first.toString(), isNot(contains(_path)));
        expect(first.toString(), isNot(contains(_origin)));
      },
    );
  });
}

SignedChatUploadClient _client(_UploadAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return SignedChatUploadClient(
    dio,
    allowedSupabaseUrl: Uri.parse(_origin),
  );
}

ChatUploadAuthorization _authorization(String url) => ChatUploadAuthorization(
  uploadId: '44444444-4444-4444-8444-444444444444',
  signedUploadUrl: Uri.parse(url),
  uploadToken: 'private-token',
  expiresAt: DateTime.utc(2099),
  expectedMimeType: 'image/jpeg',
  expectedSizeBytes: _bytes.length,
);

Future<Object> _capture(Future<void> future) async {
  try {
    await future;
  } catch (error) {
    return error;
  }
  throw StateError('Expected operation to fail');
}

class _UploadAdapter implements HttpClientAdapter {
  _UploadAdapter({
    this.status = 200,
    this.responseBody = '',
    this.errorType,
    this.waitForCancellation = false,
  });

  final int status;
  final String responseBody;
  final DioExceptionType? errorType;
  final bool waitForCancellation;
  RequestOptions? request;
  Uint8List bytes = Uint8List(0);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    if (waitForCancellation) {
      if (cancelFuture == null) throw StateError('Missing cancellation future');
      await cancelFuture;
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.cancel,
      );
    }
    if (errorType != null) {
      throw DioException(requestOptions: options, type: errorType!);
    }
    final builder = BytesBuilder(copy: false);
    await for (final chunk
        in requestStream ?? const Stream<Uint8List>.empty()) {
      builder.add(chunk);
    }
    bytes = builder.takeBytes();
    return ResponseBody.fromString(responseBody, status);
  }

  @override
  void close({bool force = false}) {}
}
