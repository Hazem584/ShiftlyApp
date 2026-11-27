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

enum PendingChatMediaType {
  text,
  location,
  image,
  document,
  voice;

  String get apiValue => switch (this) {
    PendingChatMediaType.text => 'TEXT',
    PendingChatMediaType.location => 'LOCATION',
    PendingChatMediaType.image => 'IMAGE',
    PendingChatMediaType.voice => 'VOICE',
    PendingChatMediaType.document => 'DOCUMENT',
  };
}
