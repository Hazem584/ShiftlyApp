import 'package:dio/dio.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import 'connection/stream_client_for.dart';
import 'connection/stream_connection_state.dart';
import 'connection/stream_query_channels.dart';
import 'connection/stream_watch_channel.dart';

class StreamChatConnection {
  StreamChatConnection(
    Dio api, {
    stream.StreamChatClient Function(String)? clientFactory,
    bool persist = true,
  }) : _state = StreamConnectionState(api, clientFactory, persist);
  final StreamConnectionState _state;
  Dio get api => _state.api;
  stream.StreamChatClient Function(String)? get clientFactory =>
      _state.clientFactory;
  bool get persist => _state.persist;
  FeatureSessionScope? get scope => _state.scope;
  Stream<stream.Event> get events => _state.events.stream;
  void bind(FeatureSessionScope? next) => _state.bind(next);
  Future<stream.StreamChatClient?> clientFor(String workspaceId) =>
      streamClientFor(_state, workspaceId);
  Future<stream.Channel> channel(String workspaceId, String groupId) =>
      watchStreamChannel(_state, workspaceId, groupId, clientFor);
  Future<Map<String, stream.Channel>> channels(
    String workspaceId,
    Set<String> allowed,
  ) => queryStreamChannels(_state, workspaceId, allowed, clientFor, channel);
  Future<void> dispose() async {
    bind(null);
    await _state.closing;
    await _state.events.close();
  }
}
