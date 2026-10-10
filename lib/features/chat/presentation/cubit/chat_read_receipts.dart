import 'dart:async';

import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

import 'chat_conversation_host.dart';
import 'chat_read_position.dart';

class ChatReadReceipts {
  ChatReadReceipts(this.host);
  final ChatConversationHost host;
  ChatReadPosition? _confirmedReadPosition;
  ChatReadPosition? _readInFlight;
  ChatReadPosition? _pendingReadPosition;
  bool _synchronizingReadConflict = false;
  void markNewestRead(List<ChatMessage> messages) {
    if (messages.isEmpty) return;
    final newest = messages.reduce(
      (current, candidate) =>
          ChatReadPosition.fromMessage(candidate)
                  .compareTo(ChatReadPosition.fromMessage(current)) >
              0
          ? candidate
          : current,
    );
    _queueRead(ChatReadPosition.fromMessage(newest));
  }

  void _queueRead(ChatReadPosition position) {
    final confirmed = _confirmedReadPosition;
    if (confirmed != null && position.compareTo(confirmed) <= 0) return;
    final inFlight = _readInFlight;
    if (_synchronizingReadConflict) {
      _pendingReadPosition = _newer(_pendingReadPosition, position);
      return;
    }
    if (inFlight != null) {
      if (position.compareTo(inFlight) > 0) {
        _pendingReadPosition = _newer(_pendingReadPosition, position);
      }
      return;
    }
    _pendingReadPosition = _newer(_pendingReadPosition, position);
    _drainReadQueue();
  }

  void _drainReadQueue({bool allowConflictSync = true}) {
    if (_readInFlight != null) return;
    final pending = _pendingReadPosition;
    final confirmed = _confirmedReadPosition;
    if (pending == null ||
        (confirmed != null && pending.compareTo(confirmed) <= 0)) {
      _pendingReadPosition = null;
      return;
    }
    _pendingReadPosition = null;
    _readInFlight = pending;
    final scope = host.scope;
    final groupId = host.groupId;
    final generation = host.generation;
    if (scope == null || groupId == null) {
      _readInFlight = null;
      return;
    }
    unawaited(
      _sendReadPosition(
        scope,
        groupId,
        generation,
        pending,
        allowConflictSync: allowConflictSync,
      ),
    );
  }

  Future<void> _sendReadPosition(
    FeatureSessionScope scope,
    String groupId,
    int generation,
    ChatReadPosition requested, {
    required bool allowConflictSync,
  }) async {
    var synchronized = false;
    try {
      await host.repository.markRead(
        scope.workspaceId,
        groupId,
        requested.messageId,
      );
      if (!_readRequestCurrent(scope, groupId, generation, requested)) return;
      _confirmedReadPosition = _newer(_confirmedReadPosition, requested);
      host.onChanged?.call();
    } catch (error) {
      if (!_readRequestCurrent(scope, groupId, generation, requested)) return;
      if (error is ApiException &&
          error.code == 'CHAT_READ_POSITION_BACKWARDS') {
        _confirmedReadPosition = _newer(_confirmedReadPosition, requested);
        host.onChanged?.call();
      } else {
        _pendingReadPosition = _newer(_pendingReadPosition, requested);
        synchronized =
            error is ApiException &&
            error.code == 'CHAT_READ_POSITION_CONFLICT' &&
            allowConflictSync;
      }
    } finally {
      if (_readRequestCurrent(scope, groupId, generation, requested)) {
        _readInFlight = null;
      }
    }
    if (!host.scopeCurrent(scope, groupId, generation)) return;
    if (synchronized) {
      _synchronizingReadConflict = true;
      await host.load(refresh: true);
      if (!host.scopeCurrent(scope, groupId, generation)) return;
      _synchronizingReadConflict = false;
      _drainReadQueue(allowConflictSync: false);
      return;
    }
    // Failures remain pending until a later safe trigger. Successful requests
    // immediately drain a newer position that arrived while they were active.
    if (_confirmedReadPosition != null &&
        _confirmedReadPosition!.compareTo(requested) >= 0) {
      _drainReadQueue();
    }
  }

  bool _readRequestCurrent(
    FeatureSessionScope scope,
    String groupId,
    int generation,
    ChatReadPosition requested,
  ) =>
      host.scopeCurrent(scope, groupId, generation) &&
      _readInFlight == requested;

  ChatReadPosition _newer(ChatReadPosition? first, ChatReadPosition second) =>
      first == null || second.compareTo(first) > 0 ? second : first;

  void clear() {
    _confirmedReadPosition = null;
    _readInFlight = null;
    _pendingReadPosition = null;
    _synchronizingReadConflict = false;
  }
}
