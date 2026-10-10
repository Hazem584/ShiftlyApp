import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:shiftly/core/storage/platform_file.dart';

Future<Database> openChatDatabase(String path) =>
    databaseFactoryIo.openDatabase(path);

Future<ChatStorageDirectory> chatStorageDirectory() async {
  final support = await getApplicationSupportDirectory();
  return ChatStorageDirectory('${support.path}/private-chat-v1');
}
