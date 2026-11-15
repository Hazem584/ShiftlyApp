import 'dart:async';

import 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import 'stream_chat_connection.dart';
import 'stream_event_subscription.dart';

ChatRealtimeSubscription listenStreamEvents(
  StreamChatConnection connection,
  ChatRealtimeSubscription old,
  void Function(stream.Event) callback,
  void Function() resync,
) {
  final scope = connection.scope;
  var cancelled = false;
  final subscription = connection.events.listen((event) {
    if (cancelled || scope != connection.scope) return;
    if (event.type == 'connection.recovered') {
      resync();
      return;
    }
    callback(event);
  });
  if (scope != null) {
    unawaited(
      connection.clientFor(scope.workspaceId).then<void>((_) {}).catchError((
        Object _,
      ) {
        if (!cancelled && scope == connection.scope) resync();
      }),
    );
  }
  return StreamEventSubscription(() async {
    cancelled = true;
    await subscription.cancel();
    await old.cancel();
  });
}
