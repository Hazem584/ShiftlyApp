String? apiErrorChatMessage(String? code) => switch (code) {
  'CHAT_GROUP_ARCHIVED' => 'This chat group is archived and read only.',
  'CHAT_GROUP_NOT_FOUND' => 'That chat group could not be found.',
  'CHAT_MEMBER_INVALID' =>
    'Choose active members from the current workspace.',
  'CHAT_CURSOR_INVALID' => 'Messages changed. Refresh the conversation.',
  'CHAT_CLIENT_MESSAGE_ID_CONFLICT' =>
    'This message conflicts with an earlier send attempt.',
  'CHAT_READ_POSITION_BACKWARDS' =>
    'Your read position is already ahead of that message.',
  'CHAT_READ_POSITION_CONFLICT' =>
    'The read position changed. Refreshing will synchronize it.',
  'CHAT_REPLY_INVALID' =>
    'The message being replied to is no longer available.',
  'CHAT_MEDIA_TYPE_UNSUPPORTED' => 'This media format is not supported.',
  'CHAT_MEDIA_TOO_LARGE' => 'The selected media is too large.',
  'CHAT_MEDIA_METADATA_INVALID' => 'The media details are invalid.',
  'CHAT_MEDIA_AUTHORIZATION_REQUIRED' =>
    'Media authorization is no longer available.',
  'CHAT_MEDIA_UPLOAD_AUTHORIZATION_FAILED' =>
    'The upload service is temporarily unavailable.',
  'CHAT_MEDIA_VERIFICATION_FAILED' =>
    'The uploaded media could not be verified.',
  'CHAT_MEDIA_OBJECT_MISSING' =>
    'The uploaded media could not be found. Please retry.',
  'CHAT_MEDIA_OBJECT_INVALID' =>
    'The uploaded media did not pass verification.',
  'CHAT_MEDIA_UPLOAD_DESTINATION_INVALID' =>
    'The upload destination is invalid. Please retry.',
  'CHAT_MEDIA_UPLOAD_METADATA_CHANGED' =>
    'The media changed after it was prepared. Please retry.',
  'CHAT_MEDIA_STORAGE_UPLOAD_FAILED' =>
    'The media upload failed. Please retry.',
  'CHAT_MEDIA_UPLOAD_TIMEOUT' =>
    'The media upload timed out. Please retry.',
  'CHAT_MEDIA_UPLOAD_CANCELLED' => 'The media upload was cancelled.',
  'CHAT_UPLOAD_NOT_FOUND' => 'That upload is no longer available.',
  'CHAT_UPLOAD_TYPE_MISMATCH' => 'The upload does not match this message.',
  'CHAT_UPLOAD_EXPIRED' => 'The upload expired. Please try again.',
  'CHAT_UPLOAD_CONSUMED' => 'This upload has already been sent.',
  'CHAT_UPLOAD_NOT_PENDING' => 'This upload is no longer pending.',
  'CHAT_MESSAGE_HAS_NO_MEDIA' => 'This message has no available media.',
  'CHAT_READ_MESSAGE_INVALID' =>
    'The selected message cannot be used as a read position.',
  _ => null,
};
