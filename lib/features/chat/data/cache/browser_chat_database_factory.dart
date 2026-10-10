import 'package:sembast_web/sembast_web.dart';
import 'package:shiftly/core/storage/platform_file.dart';

Future<Database> openChatDatabase(String path) =>
    databaseFactoryWeb.openDatabase(path);

Future<ChatStorageDirectory> chatStorageDirectory() async =>
    ChatStorageDirectory('private-chat-v1');
