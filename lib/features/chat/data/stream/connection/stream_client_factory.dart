import 'package:flutter/foundation.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import 'package:stream_chat_persistence/stream_chat_persistence.dart'
    as persistence;

import 'stream_connection_state.dart';

stream.StreamChatClient createStreamClient(
  StreamConnectionState state,
  Map auth,
) {
  final client =
      state.clientFactory?.call(auth['apiKey'] as String) ??
      stream.StreamChatClient(
        auth['apiKey'] as String,
        logLevel: stream.Level.OFF,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 12),
      );
  if (state.persist && !kIsWeb) {
    client.chatPersistenceClient = persistence.StreamChatPersistenceClient(
      logLevel: stream.Level.OFF,
      connectionMode: persistence.ConnectionMode.background,
    );
  }
  return client;
}
