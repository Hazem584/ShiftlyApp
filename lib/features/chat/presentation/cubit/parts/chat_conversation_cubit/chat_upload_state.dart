part of '../../chat_conversation_cubit.dart';

enum ChatUploadState {
  preparing,
  uploading,
  finalizing,
  sent,
  failed,
  cancelled,
}
