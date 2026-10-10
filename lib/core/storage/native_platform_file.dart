import 'dart:io';

import 'package:path_provider/path_provider.dart';

typedef ChatLocalFile = File;
typedef ChatStorageDirectory = Directory;

Future<Uri> chatFilePlaybackUri(ChatLocalFile file) async => file.uri;

Future<String> chatRecordingPath() async {
  final directory = await getTemporaryDirectory();
  return '${directory.path}/shiftly-voice-${DateTime.now().microsecondsSinceEpoch}.m4a';
}
