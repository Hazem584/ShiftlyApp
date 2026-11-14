import 'dart:async';

import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import 'stream_chat_connection.dart';
import 'stream_chat_mapper.dart';

class StreamChatRealtime implements ChatLiveRealtime, ChatGroupStateRealtime {
  StreamChatRealtime(this.connection, this.legacy);
  final StreamChatConnection connection;
  final ChatLiveRealtime legacy;
  @override
  ChatRealtimeSubscription subscribeToGroup(
    String groupId,
    void Function() changed,
  ) => subscribeToMessages(
    groupId,
    connection.scope?.membershipId ?? '',
    (_) => changed(),
    changed,
  );
  @override
  ChatRealtimeSubscription subscribeToMessages(
    String groupId,
    String membershipId,
    void Function(ChatMessage) message,
    void Function() resync,
  ) {
    final old = legacy.subscribeToMessages(
      groupId,
      membershipId,
      message,
      resync,
    );
    return _listen(old, (event) {
      if (event.cid != 'shiftly:$groupId') {
        return;
      }
      final value = event.message;
      if (value != null && StreamChatMapper.supported(value)) {
        message(StreamChatMapper.message(value, groupId));
      } else if (event.type != 'typing.start' && event.type != 'typing.stop') {
        resync();
      }
    }, resync);
  }

  @override
  ChatRealtimeSubscription subscribeToInbox(
    String workspaceId,
    String membershipId,
    void Function() changed,
  ) => _listen(legacy.subscribeToInbox(workspaceId, membershipId, changed), (
    event,
  ) {
    if (event.cid?.startsWith('shiftly:') == true ||
        event.type.startsWith('notification.')) {
      changed();
    }
  }, changed);
  @override
  ChatRealtimeSubscription subscribeToGroupState(
    String groupId,
    void Function() changed,
  ) => _listen(
    (legacy as ChatGroupStateRealtime).subscribeToGroupState(groupId, changed),
    (event) {
      if (event.cid == 'shiftly:$groupId' &&
          event.message == null &&
          event.type != 'typing.start' &&
          event.type != 'typing.stop') {
        changed();
      }
    },
    changed,
  );
  ChatRealtimeSubscription _listen(
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
    return _StreamSubscription(() async {
      cancelled = true;
      await subscription.cancel();
      await old.cancel();
    });
  }
}

class _StreamSubscription implements ChatRealtimeSubscription {
  _StreamSubscription(this.stop);
  final Future<void> Function() stop;
  @override
  Future<void> cancel() => stop();
}
