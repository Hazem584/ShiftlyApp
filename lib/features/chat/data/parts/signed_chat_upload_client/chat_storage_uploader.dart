part of '../../signed_chat_upload_client.dart';

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
