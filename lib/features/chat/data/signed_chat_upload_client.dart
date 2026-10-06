import 'dart:typed_data';

import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/chat/data/chat_models.dart';
import 'package:shiftly/features/chat/data/chat_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ChatStorageUploader {
  Future<void> upload({
    required String bucket,
    required String path,
    required String uploadToken,
    required Uint8List bytes,
    required String mimeType,
    required bool upsert,
  });
}

class SupabaseChatStorageUploader implements ChatStorageUploader {
  const SupabaseChatStorageUploader(this._client);

  final SupabaseClient _client;

  @override
  Future<void> upload({
    required String bucket,
    required String path,
    required String uploadToken,
    required Uint8List bytes,
    required String mimeType,
    required bool upsert,
  }) async {
    await _client.storage
        .from(bucket)
        .uploadBinaryToSignedUrl(
          path,
          uploadToken,
          bytes,
          FileOptions(contentType: mimeType, upsert: upsert),
        );
  }
}

class SignedChatUploadClient {
  const SignedChatUploadClient(this._uploader);

  final ChatStorageUploader _uploader;

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
    if (cancellation?.isCancelled == true) throw _cancelled();
    try {
      await _uploader.upload(
        bucket: authorization.bucket,
        path: authorization.path,
        uploadToken: authorization.uploadToken,
        bytes: bytes,
        mimeType: mimeType,
        upsert: false,
      );
      if (cancellation?.isCancelled == true) throw _cancelled();
      onProgress?.call(bytes.length, bytes.length);
    } on ApiException {
      rethrow;
    } on StorageException catch (error) {
      final statusCode = int.tryParse(error.statusCode ?? '');
      throw ApiException(
        statusCode: statusCode,
        message: 'The media upload failed. Please try again.',
        code: 'CHAT_MEDIA_STORAGE_UPLOAD_FAILED',
        kind: statusCode != null && statusCode >= 500
            ? FailureKind.server
            : statusCode != null
            ? FailureKind.validation
            : FailureKind.network,
      );
    } catch (_) {
      throw const ApiException(
        message: 'The media upload failed. Please try again.',
        code: 'CHAT_MEDIA_STORAGE_UPLOAD_FAILED',
        kind: FailureKind.unknown,
      );
    }
  }

  ApiException _cancelled() => const ApiException(
    message: 'Upload cancelled.',
    code: 'CHAT_MEDIA_UPLOAD_CANCELLED',
    kind: FailureKind.cancelled,
  );
}
