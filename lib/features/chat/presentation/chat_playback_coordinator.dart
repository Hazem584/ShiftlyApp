import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_scope.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_cache.dart';
import 'package:shiftly/features/chat/data/chat_models.dart';
import 'package:shiftly/features/chat/data/chat_repository.dart';

/// One conversation player and selection generation, shared by every bubble.
class ChatPlaybackCoordinator {
  ChatPlaybackCoordinator(this.player, this.cache) {
    cache.storage.listeners.add(_invalidate);
  }
  final AudioPlayer player;
  final ChatMediaCache cache;
  int _selection = 0;
  ChatCacheScope? _scope;
  Future<void> play(
    ChatCacheScope scope,
    ChatMessage message,
    ChatRepository repository,
  ) async {
    final selection = ++_selection;
    _scope = scope;
    final file = await cache.resolve(scope, message, repository);
    if (selection != _selection || !cache.storage.authorized(scope)) return;
    await _load(scope, file, message.id, selection);
  }

  Future<void> playPending(ChatCacheScope scope, File file, String id) async {
    final selection = ++_selection;
    _scope = scope;
    await _load(scope, file, id, selection);
  }

  Future<void> _load(
    ChatCacheScope scope,
    File file,
    String id,
    int selection,
  ) async {
    if (selection != _selection || !cache.storage.authorized(scope)) return;
    cache.pin(file);
    final position =
        player.sequenceState.currentSource?.tag == id &&
            player.processingState != ProcessingState.completed
        ? player.position
        : Duration.zero;
    bool handedToPlayer = false;
    try {
      await player.setAudioSource(
        AudioSource.uri(Uri.file(file.path), tag: id),
      );
      if (selection != _selection || !cache.storage.authorized(scope)) return;
      if (position > Duration.zero) await player.seek(position);
      if (selection != _selection || !cache.storage.authorized(scope)) return;
      final completion = player.play();
      handedToPlayer = true;
      unawaited(
        completion
            .catchError((Object _) {})
            .whenComplete(() => cache.unpin(file)),
      );
    } finally {
      if (!handedToPlayer) cache.unpin(file);
    }
  }

  void pause() {
    _selection++;
    unawaited(player.pause());
  }

  void _invalidate() {
    final scope = _scope;
    if (scope != null && !cache.storage.authorized(scope)) {
      _selection++;
      unawaited(player.stop());
      unawaited(player.setAudioSources([]));
    }
  }

  void close() {
    _selection++;
    cache.storage.listeners.remove(_invalidate);
  }
}
