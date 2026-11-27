import 'dart:typed_data';

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
