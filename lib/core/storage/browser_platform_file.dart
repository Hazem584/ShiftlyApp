import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:sembast_web/sembast_web.dart';

final _mediaDatabase = databaseFactoryWeb.openDatabase(
  'shiftly-private-media-v1',
);
final _files = stringMapStoreFactory.store('files');

/// Private bytes, never signed URLs. Access is checked by the chat cache layer.
class ChatLocalFile {
  ChatLocalFile(this.path);
  final String path;
  Uri get uri => Uri(path: path);

  Future<bool> exists() async =>
      await _files.record(path).exists(await _mediaDatabase);

  Future<Uint8List> readAsBytes() async {
    // Browser microphone recordings are blob URLs owned by record_web.
    if (path.startsWith('blob:')) return XFile(path).readAsBytes();
    final value = await _files.record(path).get(await _mediaDatabase);
    if (value == null) throw StateError('Private media unavailable');
    return base64Decode(value['bytes'] as String);
  }

  Future<int> length() async => (await readAsBytes()).length;

  Future<ChatLocalFile> writeAsBytes(
    List<int> bytes, {
    bool flush = false,
  }) async {
    await _files.record(path).put(await _mediaDatabase, {
      'bytes': base64Encode(bytes),
    });
    return this;
  }

  Future<ChatLocalFile> rename(String target) async {
    final database = await _mediaDatabase;
    await database.transaction((transaction) async {
      final value = await _files.record(path).get(transaction);
      if (value == null) throw StateError('Private media unavailable');
      await _files.record(target).put(transaction, value);
      await _files.record(path).delete(transaction);
    });
    return ChatLocalFile(target);
  }

  Future<ChatLocalFile> delete() async {
    if (!path.startsWith('blob:')) {
      await _files.record(path).delete(await _mediaDatabase);
    }
    return this;
  }

  BrowserFileSink openWrite() => BrowserFileSink(this);
}

class BrowserFileSink {
  BrowserFileSink(this.file);
  final ChatLocalFile file;
  final _bytes = BytesBuilder(copy: false);
  bool _closed = false;
  void add(List<int> bytes) => _bytes.add(bytes);
  Future<void> flush() async {}
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await file.writeAsBytes(_bytes.takeBytes());
  }
}

class ChatStorageDirectory {
  ChatStorageDirectory(this.path);
  final String path;
  Future<void> create({bool recursive = false}) async {
    await _mediaDatabase;
  }

  Stream<ChatLocalFile> list() async* {
    final rows = await _files.find(await _mediaDatabase);
    for (final row in rows) {
      if (row.key.startsWith('$path/')) yield ChatLocalFile(row.key);
    }
  }
}

Future<Uri> chatFilePlaybackUri(ChatLocalFile file) async {
  final bytes = await file.readAsBytes();
  final webm = bytes.length >= 4 && bytes[0] == 0x1a && bytes[1] == 0x45;
  final ogg =
      bytes.length >= 4 &&
      ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'OggS';
  return Uri.dataFromBytes(
    bytes,
    mimeType: webm
        ? 'audio/webm'
        : ogg
        ? 'audio/ogg'
        : 'audio/mp4',
  );
}

Future<String> chatRecordingPath() async => 'shiftly-voice.webm';
