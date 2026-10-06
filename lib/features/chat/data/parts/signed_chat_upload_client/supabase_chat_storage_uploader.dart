part of '../../signed_chat_upload_client.dart';

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
