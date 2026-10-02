import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/chat/data/chat_models.dart';
import 'package:shiftly/features/chat/data/chat_repository.dart';

class SignedChatUploadClient {
  SignedChatUploadClient(this._dio, {required Uri allowedSupabaseUrl})
    : _allowedOrigin = allowedSupabaseUrl {
    if (allowedSupabaseUrl.scheme != 'https' ||
        allowedSupabaseUrl.host.isEmpty ||
        allowedSupabaseUrl.userInfo.isNotEmpty ||
        allowedSupabaseUrl.query.isNotEmpty ||
        allowedSupabaseUrl.fragment.isNotEmpty) {
      throw ArgumentError('Invalid allowed Supabase origin');
    }
  }

  final Dio _dio;
  final Uri _allowedOrigin;

  Future<void> upload({
    required ChatUploadAuthorization authorization,
    required Uint8List bytes,
    required String mimeType,
    void Function(int sent, int total)? onProgress,
    ChatUploadCancellation? cancellation,
  }) async {
    if (bytes.isEmpty ||
        authorization.expectedMimeType != mimeType ||
        authorization.expectedSizeBytes != bytes.length) {
      throw const ApiException(
        message: 'The upload metadata changed. Please try again.',
        code: 'CHAT_MEDIA_UPLOAD_METADATA_CHANGED',
        kind: FailureKind.validation,
      );
    }
    final destination = _validatedDestination(authorization);
    final cancelToken = CancelToken();
    cancellation?.bind(() => cancelToken.cancel());
    try {
      final response = await _dio.putUri<Object?>(
        destination,
        data: bytes,
        cancelToken: cancelToken,
        options: Options(
          contentType: mimeType,
          headers: {
            Headers.contentLengthHeader: bytes.length,
            'x-upsert': 'false',
          },
          followRedirects: false,
          receiveDataWhenStatusError: false,
          validateStatus: (_) => true,
        ),
        onSendProgress: onProgress,
      );
      final status = response.statusCode;
      if (status == null || status < 200 || status >= 300) {
        throw _storageFailure(status);
      }
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        throw const ApiException(
          message: 'Upload cancelled.',
          code: 'CHAT_MEDIA_UPLOAD_CANCELLED',
          kind: FailureKind.cancelled,
        );
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        throw const ApiException(
          message: 'The upload timed out. Please try again.',
          code: 'CHAT_MEDIA_UPLOAD_TIMEOUT',
          kind: FailureKind.timeout,
        );
      }
      throw const ApiException(
        message: 'The media upload failed. Please try again.',
        code: 'CHAT_MEDIA_STORAGE_UPLOAD_FAILED',
        kind: FailureKind.network,
      );
    } catch (_) {
      throw const ApiException(
        message: 'The media upload failed. Please try again.',
        code: 'CHAT_MEDIA_STORAGE_UPLOAD_FAILED',
        kind: FailureKind.unknown,
      );
    } finally {
      cancellation?.unbind();
    }
  }

  Uri _validatedDestination(ChatUploadAuthorization authorization) {
    final source = authorization.signedUploadUrl;
    const pathPrefix = '/storage/v1/object/upload/sign/chat-media/';
    if (source.scheme != 'https' ||
        source.host.toLowerCase() != _allowedOrigin.host.toLowerCase() ||
        source.port != _allowedOrigin.port ||
        source.userInfo.isNotEmpty ||
        source.fragment.isNotEmpty ||
        !source.path.startsWith(pathPrefix) ||
        source.path.length <= pathPrefix.length ||
        source.pathSegments.any((segment) => segment == '..')) {
      throw _invalidDestination();
    }
    final tokenValues = source.queryParametersAll['token'];
    if (tokenValues != null) {
      if (tokenValues.length != 1 ||
          tokenValues.single != authorization.uploadToken) {
        throw _invalidDestination();
      }
      return source;
    }
    final query = <String, dynamic>{...source.queryParametersAll};
    query['token'] = authorization.uploadToken;
    return source.replace(queryParameters: query);
  }

  ApiException _invalidDestination() => const ApiException(
    message: 'The upload destination is invalid. Please try again.',
    code: 'CHAT_MEDIA_UPLOAD_DESTINATION_INVALID',
    kind: FailureKind.validation,
  );

  ApiException _storageFailure(int? status) => ApiException(
    statusCode: status,
    message: 'The media upload failed. Please try again.',
    code: 'CHAT_MEDIA_STORAGE_UPLOAD_FAILED',
    kind: status != null && status >= 500
        ? FailureKind.server
        : FailureKind.validation,
  );
}
