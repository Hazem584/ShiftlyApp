String streamUploadFileName(String type, String mime) {
  final extension = switch (mime.toLowerCase()) {
    'image/png' => 'png',
    'image/webp' => 'webp',
    'image/jpeg' => 'jpg',
    'audio/webm' => 'webm',
    'audio/ogg' => 'ogg',
    'audio/mpeg' => 'mp3',
    'audio/aac' => 'aac',
    'audio/mp4' || 'audio/x-m4a' => 'm4a',
    _ => 'bin',
  };
  return '${type == 'VOICE'
      ? 'voice'
      : type == 'IMAGE'
      ? 'image'
      : 'document'}.$extension';
}
