part of '../../chat_conversation_cubit.dart';

enum ChatUploadState {
  queued,
  sending,
  uncertain,
  preparing,
  uploading,
  finalizing,
  sent,
  failed,
  cancelled,
}
