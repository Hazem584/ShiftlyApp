import 'dart:async';

import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';

import 'chat_conversation_host.dart';

class ChatLiveSync {
  ChatLiveSync(this.host);
  final ChatConversationHost host;
  bool _syncing = false, _again = false;
  ChatRealtimeSubscription bind(ChatLiveRealtime realtime, String groupId) {
    final scope = host.scope!, generation = host.generation;
    return realtime.subscribeToMessages(
      groupId,
      scope.membershipId,
      (message) {
        if (host.scopeCurrent(scope, groupId, generation)) accept(message);
      },
      () {
        if (host.scopeCurrent(scope, groupId, generation)) unawaited(resync());
      },
    );
  }

  void accept(ChatMessage message) {
    final scope = host.scope, group = host.groupId;
    if (scope == null ||
        group == null ||
        host.isClosed ||
        host.state.accessLost ||
        message.groupId != group) {
      return;
    }
    final current = host.state.messages
        .where((m) => m.id == message.id)
        .firstOrNull;
    if (current != null && current.revision > message.revision) return;
    final merged = host.mergeMessages([message], host.state.messages);
    host.emitState(
      host.state.copyWith(
        loading: false,
        messages: merged,
        pending: host.confirmPending(merged),
      ),
    );
    host.markNewestRead(merged);
    final key = host.cacheScope;
    if (key != null) {
      unawaited(
        host.messageCache?.confirm(key, message).catchError((Object _) {}) ??
            Future<void>.value(),
      );
    }
  }

  Future<void> resync() async {
    if (_syncing) {
      _again = true;
      return;
    }
    final scope = host.scope,
        group = host.groupId,
        generation = host.generation;
    if (scope == null || group == null || host.isClosed) return;
    _syncing = true;
    try {
      await host.load(refresh: true);
      if (!host.scopeCurrent(scope, group, generation) ||
          host.state.accessLost) {
        return;
      }
      final ids = host.state.messages.map((m) => m.id).take(500).toList();
      final rows = await host.repository.reconcileMessages(
        scope.workspaceId,
        group,
        ids,
      );
      if (!host.scopeCurrent(scope, group, generation)) return;
      for (final row in rows) {
        accept(row);
      }
    } on ApiException catch (error) {
      if (host.scopeCurrent(scope, group, generation) &&
          (error.statusCode == 403 ||
              (error.statusCode == 404 &&
                  error.code == 'CHAT_GROUP_NOT_FOUND'))) {
        await host.loseAccess();
      }
    } catch (_) {
      /* Existing cache stays visible; reconnect/foreground retries. */
    } finally {
      _syncing = false;
      if (_again && !host.isClosed) {
        _again = false;
        unawaited(resync());
      }
    }
  }
}
