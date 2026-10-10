import 'dart:async';
import 'dart:typed_data';

import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/entities/chat_outbox_operation.dart';
import 'package:shiftly/features/chat/domain/services/chat_media_validation.dart';

import 'chat_conversation_host.dart';
import 'chat_message_delivery.dart';
import 'chat_message_uuid.dart';
import 'chat_outbox_queue.dart';
import 'pending_chat_message.dart';

class ChatOutboxController {
  ChatOutboxController(this.host);
  final ChatConversationHost host;
  final queue = ChatOutboxQueue();
  late final _delivery = ChatMessageDelivery(host, queue, _showOperation);
  bool _outgoingRunning = false;
  bool _accepting = false;
  Future<bool> send(String value) async {
    final text = value.trim();
    if (text.isEmpty || text.length > 4000) return false;
    return _accept(
      ChatOutboxOperation(
        id: chatMessageUuid(),
        type: 'TEXT',
        text: text,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<bool> retrySend() async {
    final operation = queue.operations.values
        .where((p) => p.type == 'TEXT' && p.phase == 'failed')
        .firstOrNull;
    if (operation == null) return false;
    await retryMedia(operation.id);
    return true;
  }

  Future<String?> sendImage(Uint8List bytes) async {
    final owned = Uint8List.fromList(bytes);
    final mime = ChatMediaValidation.imageMime(owned);
    if (mime == null) return null;
    return _acceptMedia('IMAGE', owned, mime);
  }

  Future<String?> sendVoice({
    required Uint8List bytes,
    required String mimeType,
    required int durationMs,
  }) async {
    final owned = Uint8List.fromList(bytes);
    if (!ChatMediaValidation.validVoice(
      bytes: owned,
      mimeType: mimeType,
      durationMs: durationMs,
    )) {
      return null;
    }
    return _acceptMedia('VOICE', owned, mimeType, durationMs: durationMs);
  }

  Future<String?> _acceptMedia(
    String type,
    Uint8List bytes,
    String mime, {
    int? durationMs,
  }) async {
    final scope = host.cacheScope;
    final generation = host.generation;
    if (scope == null || _accepting) return null;
    String? file;
    try {
      file = await host.outbox?.ownMedia(scope, bytes);
      final operation = ChatOutboxOperation(
        id: chatMessageUuid(),
        type: type,
        createdAt: DateTime.now().toUtc(),
        file: file,
        mimeType: mime,
        sizeBytes: bytes.length,
        durationMs: durationMs,
      );
      if (generation != host.generation ||
          host.cacheScope?.key != scope.key ||
          host.isClosed) {
        if (file != null) await host.outbox!.remove(scope, operation);
        return null;
      }
      if (await _accept(operation, bytes: bytes)) return operation.id;
      if (file != null) await host.outbox!.remove(scope, operation);
    } catch (_) {
      if (!host.isClosed) {
        host.emitState(
          host.state.copyWith(
            failure: const Failure(
              message: 'Unable to save media. Keep it and try again.',
              kind: FailureKind.server,
            ),
          ),
        );
      }
    }
    return null;
  }

  Future<bool> sendLocation(ChatLocation location) async {
    if (!location.isValid) return false;
    return _accept(
      ChatOutboxOperation(
        id: chatMessageUuid(),
        type: 'LOCATION',
        location: location,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<bool> _accept(
    ChatOutboxOperation operation, {
    Uint8List? bytes,
  }) async {
    final scope = host.scope;
    final group = host.groupId;
    final key = host.cacheScope;
    if (scope == null ||
        group == null ||
        key == null ||
        host.state.accessLost ||
        _accepting ||
        (host.outbox != null && !host.outbox!.storage.writable(key))) {
      return false;
    }
    final generation = host.generation;
    _accepting = true;
    try {
      await host.outbox?.save(key, operation);
      if (!host.scopeCurrent(scope, group, generation)) {
        await host.outbox?.remove(key, operation);
        return false;
      }
      queue.operations[operation.id] = operation;
      if (bytes != null) queue.localBytes[operation.id] = bytes;
      _showOperation(operation);
      unawaited(drain());
      return true; // Accepted durably, not a delivery acknowledgement.
    } catch (_) {
      if (host.scopeCurrent(scope, group, generation)) {
        host.emitState(
          host.state.copyWith(
            failure: const Failure(
              message:
                  'Unable to save this message. Keep your input and retry.',
              kind: FailureKind.server,
            ),
          ),
        );
      }
      return false;
    } finally {
      _accepting = false;
    }
  }

  void _showOperation(ChatOutboxOperation operation, {Failure? failure}) {
    final type = switch (operation.type) {
      'TEXT' => PendingChatMediaType.text,
      'LOCATION' => PendingChatMediaType.location,
      'IMAGE' => PendingChatMediaType.image,
      _ => PendingChatMediaType.voice,
    };
    final status = switch (operation.phase) {
      'queued' => ChatUploadState.queued,
      'sending' => ChatUploadState.sending,
      'preparing' => ChatUploadState.preparing,
      'uploading' => ChatUploadState.uploading,
      'finalizing' => ChatUploadState.finalizing,
      _ =>
        operation.submitted
            ? ChatUploadState.uncertain
            : ChatUploadState.failed,
    };
    final value = PendingChatMessage(
      clientMessageId: operation.id,
      mediaType: type,
      status: status,
      text: operation.text,
      location: operation.location,
      localPath: operation.file == null
          ? null
          : host.outbox?.mediaFile(operation.file!).path,
      previewBytes: type == PendingChatMediaType.image
          ? queue.localBytes[operation.id]
          : null,
      durationMs: operation.durationMs,
      failure: failure,
      canCancel:
          !operation.submitted &&
          operation.phase != 'uploading' &&
          operation.phase != 'preparing',
    );
    final pending = [...host.state.pending];
    final index = pending.indexWhere((p) => p.clientMessageId == operation.id);
    if (index < 0) {
      pending.add(value);
    } else {
      pending[index] = value;
    }
    host.emitState(host.state.copyWith(pending: pending, clearFailure: true));
  }

  Future<void> restore() async {
    final key = host.cacheScope;
    final scope = host.scope;
    final group = host.groupId;
    final generation = host.generation;
    if (key == null || host.outbox == null || scope == null || group == null) {
      return;
    }
    final restored = await host.outbox!.restore(key);
    if (!host.scopeCurrent(scope, group, generation)) return;
    for (final operation in restored) {
      // Only never-submitted queue entries auto-resume. Everything else requires an explicit retry.
      if (operation.phase != 'queued') operation.phase = 'failed';
      queue.operations[operation.id] = operation;
      _showOperation(operation);
    }
  }

  Future<void> retryMedia(String id) async {
    final operation = queue.operations[id];
    if (operation == null ||
        operation.phase != 'failed' ||
        host.state.accessLost) {
      return;
    }
    operation.phase = 'queued';
    try {
      await host.outbox?.save(host.cacheScope!, operation);
      _showOperation(operation);
      await drain();
    } catch (_) {
      operation.phase = 'failed';
      _showOperation(operation);
    }
  }

  Future<void> drain() async {
    if (_outgoingRunning) return;
    _outgoingRunning = true;
    final generation = host.generation;
    try {
      while (!host.isClosed && generation == host.generation) {
        if (host.cacheScope == null ||
            (host.outbox != null &&
                !host.outbox!.storage.writable(host.cacheScope!))) {
          break;
        }
        final operation = queue.operations.values
            .where((p) => p.phase == 'queued')
            .firstOrNull;
        if (operation == null) break;
        await _delivery.submit(operation, generation);
      }
    } finally {
      _outgoingRunning = false;
      if (!host.isClosed &&
          generation != host.generation &&
          queue.operations.values.any((p) => p.phase == 'queued')) {
        unawaited(drain());
      }
    }
  }

  Future<void> cancelPending(String id) async {
    final operation = queue.operations[id];
    final key = host.cacheScope;
    if (operation == null ||
        key == null ||
        operation.submitted ||
        !const ['queued', 'failed'].contains(operation.phase)) {
      return;
    }
    operation.phase = 'cancelled';
    if (operation.uploadId != null) {
      try {
        await host.repository.cancelUpload(
          key.workspaceId,
          key.groupId,
          operation.uploadId!,
        );
      } catch (_) {
        operation.phase = 'failed';
        _showOperation(operation);
        return;
      }
    }
    await host.outbox?.remove(key, operation);
    queue.operations.remove(id);
    queue.localBytes.remove(id);
    queue.authorizations.remove(id);
    if (!host.isClosed && host.cacheScope?.key == key.key) {
      host.emitState(
        host.state.copyWith(
          pending: host.state.pending
              .where((p) => p.clientMessageId != id)
              .toList(),
        ),
      );
    }
  }

  void clear() {
    queue.uploadCancellation?.cancel();
    queue.operations.clear();
    queue.localBytes.clear();
    queue.authorizations.clear();
    // Preserve durable operations on route close. Never DELETE an uncertain finalized upload.
  }

  List<PendingChatMessage> withoutCanonicalPending(List<ChatMessage> messages) {
    final canonicalClientIds = messages
        .map((message) => message.clientMessageId)
        .whereType<String>()
        .toSet();
    if (canonicalClientIds.isEmpty) return host.state.pending;
    for (final id in canonicalClientIds) {
      final operation = queue.operations.remove(id);
      queue.localBytes.remove(id);
      queue.authorizations.remove(id);
      if (operation != null && host.cacheScope != null) {
        unawaited(
          host.outbox?.remove(host.cacheScope!, operation) ??
              Future<void>.value(),
        );
      }
    }
    return host.state.pending
        .where(
          (pending) => !canonicalClientIds.contains(pending.clientMessageId),
        )
        .toList(growable: false);
  }
}
