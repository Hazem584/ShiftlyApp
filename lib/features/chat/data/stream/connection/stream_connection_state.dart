import 'dart:async';

import 'package:dio/dio.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

class StreamConnectionState {
  StreamConnectionState(this.api, this.clientFactory, this.persist);
  final Dio api;
  final stream.StreamChatClient Function(String)? clientFactory;
  final bool persist;
  FeatureSessionScope? scope;
  stream.StreamChatClient? client;
  Future<stream.StreamChatClient?>? connecting;
  Future<void> closing = Future.value();
  final events = StreamController<stream.Event>.broadcast();
  StreamSubscription<stream.Event>? subscription;
  final watched = <String>{};
  final watching = <String, Future<stream.Channel>>{};
  int generation = 0;
  void bind(FeatureSessionScope? next) {
    if (scope == next) return;
    generation++;
    scope = next;
    final previous = client;
    client = null;
    connecting = null;
    watched.clear();
    watching.clear();
    unawaited(subscription?.cancel());
    subscription = null;
    if (previous != null) {
      closing = closing
          .then((_) => previous.disconnectUser(flushChatPersistence: true))
          .catchError((Object _) {});
    }
  }

  void check(FeatureSessionScope expected, int expectedGeneration) {
    if (scope != expected || expectedGeneration != generation) {
      throw StateError('Chat session changed.');
    }
  }
}
