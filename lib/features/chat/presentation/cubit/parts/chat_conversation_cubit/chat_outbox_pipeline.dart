part of '../../chat_conversation_cubit.dart';

extension ChatOutboxPipeline on ChatConversationCubit {
  Future<T> _retryIdempotent<T>(
    Future<T> Function() submit,
    bool Function() current,
  ) async {
    try {
      return await submit();
    } on ApiException catch (error) {
      final retryable =
          error.kind == FailureKind.network ||
          error.kind == FailureKind.timeout ||
          (error.statusCode ?? 0) >= 500;
      if (!retryable || !current()) rethrow;
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!current()) throw StateError('Chat access unavailable');
      return submit(); // Exactly one bounded retry; the UUID/payload stay unchanged.
    }
  }

  Future<bool> send(String value) async {
    final text = value.trim();
    if (text.isEmpty || text.length > 4000) return false;
    return _accept(
      ChatOutboxOperation(
        id: _uuidV4(),
        type: 'TEXT',
        text: text,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<bool> retrySend() async {
    final operation = _operations.values
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
    final scope = _cacheScope;
    final generation = _generation;
    if (scope == null || _accepting) return null;
    String? file;
    try {
      file = await outbox?.ownMedia(scope, bytes);
      final operation = ChatOutboxOperation(
        id: _uuidV4(),
        type: type,
        createdAt: DateTime.now().toUtc(),
        file: file,
        mimeType: mime,
        sizeBytes: bytes.length,
        durationMs: durationMs,
      );
      if (generation != _generation ||
          _cacheScope?.key != scope.key ||
          isClosed) {
        if (file != null) await outbox!.remove(scope, operation);
        return null;
      }
      if (await _accept(operation, bytes: bytes)) return operation.id;
      if (file != null) await outbox!.remove(scope, operation);
    } catch (_) {
      if (!isClosed) {
        _emitOutboxState(
          state.copyWith(
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
        id: _uuidV4(),
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
    final scope = _scope;
    final group = _groupId;
    final key = _cacheScope;
    if (scope == null ||
        group == null ||
        key == null ||
        state.accessLost ||
        _accepting ||
        (outbox != null && !outbox!.storage.writable(key))) {
      return false;
    }
    final generation = _generation;
    _accepting = true;
    try {
      await outbox?.save(key, operation);
      if (!_scopeCurrent(scope, group, generation)) {
        await outbox?.remove(key, operation);
        return false;
      }
      _operations[operation.id] = operation;
      if (bytes != null) _localBytes[operation.id] = bytes;
      _showOperation(operation);
      unawaited(_drainOutgoing());
      return true; // Accepted durably, not a delivery acknowledgement.
    } catch (_) {
      if (_scopeCurrent(scope, group, generation)) {
        _emitOutboxState(
          state.copyWith(
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
          : outbox?.mediaFile(operation.file!).path,
      previewBytes: type == PendingChatMediaType.image
          ? _localBytes[operation.id]
          : null,
      durationMs: operation.durationMs,
      failure: failure,
      canCancel:
          !operation.submitted &&
          operation.phase != 'uploading' &&
          operation.phase != 'preparing',
    );
    final pending = [...state.pending];
    final index = pending.indexWhere((p) => p.clientMessageId == operation.id);
    if (index < 0) {
      pending.add(value);
    } else {
      pending[index] = value;
    }
    _emitOutboxState(state.copyWith(pending: pending, clearFailure: true));
  }

  Future<void> _restoreOutbox() async {
    final key = _cacheScope;
    final scope = _scope;
    final group = _groupId;
    final generation = _generation;
    if (key == null || outbox == null || scope == null || group == null) return;
    final restored = await outbox!.restore(key);
    if (!_scopeCurrent(scope, group, generation)) return;
    for (final operation in restored) {
      // Only never-submitted queue entries auto-resume. Everything else requires an explicit retry.
      if (operation.phase != 'queued') operation.phase = 'failed';
      _operations[operation.id] = operation;
      _showOperation(operation);
    }
  }

  Future<void> retryMedia(String id) async {
    final operation = _operations[id];
    if (operation == null || operation.phase != 'failed' || state.accessLost) {
      return;
    }
    operation.phase = 'queued';
    try {
      await outbox?.save(_cacheScope!, operation);
      _showOperation(operation);
      await _drainOutgoing();
    } catch (_) {
      operation.phase = 'failed';
      _showOperation(operation);
    }
  }

  Future<void> _drainOutgoing() async {
    if (_outgoingRunning) return;
    _outgoingRunning = true;
    final generation = _generation;
    try {
      while (!isClosed && generation == _generation) {
        if (_cacheScope == null ||
            (outbox != null && !outbox!.storage.writable(_cacheScope!))) {
          break;
        }
        final operation = _operations.values
            .where((p) => p.phase == 'queued')
            .firstOrNull;
        if (operation == null) break;
        await _submit(operation, generation);
      }
    } finally {
      _outgoingRunning = false;
      if (!isClosed &&
          generation != _generation &&
          _operations.values.any((p) => p.phase == 'queued')) {
        unawaited(_drainOutgoing());
      }
    }
  }

  Future<void> _submit(ChatOutboxOperation operation, int generation) async {
    final scope = _scope;
    final group = _groupId;
    final key = _cacheScope;
    if (scope == null || group == null || key == null) return;
    bool current() =>
        _scopeCurrent(scope, group, generation) &&
        _operations[operation.id] == operation &&
        (outbox == null || outbox!.storage.writable(key));
    Future<void> phase(String value, {bool submitted = false}) async {
      if (!current()) throw StateError('Chat access unavailable');
      operation.phase = value;
      operation.submitted = operation.submitted || submitted;
      await outbox?.save(key, operation);
      if (!current()) throw StateError('Chat access unavailable');
      _showOperation(operation);
    }

    await outbox?.coordinator.acquire();
    try {
      if (!current()) return;
      ChatMessage canonical;
      if (operation.type == 'TEXT' || operation.type == 'LOCATION') {
        await phase('sending', submitted: true);
        canonical = operation.type == 'TEXT'
            ? await _retryIdempotent(
                () => _repository.sendMessage(
                  scope.workspaceId,
                  group,
                  text: operation.text!,
                  clientMessageId: operation.id,
                ),
                current,
              )
            : await _retryIdempotent(
                () => _repository.sendLocation(
                  scope.workspaceId,
                  group,
                  location: operation.location!,
                  clientMessageId: operation.id,
                ),
                current,
              );
      } else {
        if (!operation.submitted) {
          await phase('preparing');
          // A restarted interrupted PUT has no persisted signed authorization. Cancel only this never-finalized upload.
          if (operation.uploadId != null &&
              !_authorizations.containsKey(operation.id)) {
            await _repository.cancelUpload(
              scope.workspaceId,
              group,
              operation.uploadId!,
            );
            operation.uploadId = null;
          }
          var authorization = _authorizations[operation.id];
          if (authorization == null ||
              !authorization.expiresAt.isAfter(DateTime.now().toUtc())) {
            if (authorization != null) {
              await _repository.cancelUpload(
                scope.workspaceId,
                group,
                authorization.uploadId,
              );
            }
            authorization = await _repository.initiateUpload(
              scope.workspaceId,
              group,
              type: operation.type,
              mimeType: operation.mimeType!,
              sizeBytes: operation.sizeBytes!,
              durationMs: operation.durationMs,
            );
            if (!current()) return;
            operation.uploadId = authorization.uploadId;
            _authorizations[operation.id] = authorization;
            await outbox?.save(key, operation);
          }
          await phase('uploading');
          final bytes =
              _localBytes[operation.id] ??
              await outbox!.mediaFile(operation.file!).readAsBytes();
          if (!current()) return;
          _uploadCancellation = ChatUploadCancellation();
          try {
            await _repository.uploadSigned(
              authorization,
              bytes,
              operation.mimeType!,
              cancellation: _uploadCancellation,
              onProgress: (sent, total) {
                if (current() && total > 0) {
                  final pending = state.pending
                      .where((p) => p.clientMessageId == operation.id)
                      .firstOrNull;
                  if (pending != null) {
                    _emitOutboxState(
                      state.copyWith(
                        pending: state.pending
                            .map(
                              (p) => p.clientMessageId == operation.id
                                  ? p.copyWith(progress: sent / total)
                                  : p,
                            )
                            .toList(),
                      ),
                    );
                  }
                }
              },
            );
          } catch (_) {
            if (current()) {
              try {
                await _repository.cancelUpload(
                  scope.workspaceId,
                  group,
                  authorization.uploadId,
                );
              } catch (_) {}
              operation.uploadId = null;
              _authorizations.remove(operation.id);
            }
            rethrow;
          }
        }
        await phase('finalizing', submitted: true);
        canonical = await _retryIdempotent(
          () => _repository.finalizeUpload(
            scope.workspaceId,
            group,
            type: operation.type,
            uploadId: operation.uploadId!,
            clientMessageId: operation.id,
          ),
          current,
        );
      }
      if (!current()) return;
      _validate([canonical], scope, group);
      if (canonical.clientMessageId != operation.id ||
          canonical.type != operation.type) {
        throw const FormatException('Invalid confirmation');
      }
      try {
        await messageCache?.confirm(key, canonical);
      } catch (_) {
        /* Delivery remains canonical even if cache is unavailable. */
      }
      if (!current()) return;
      await outbox?.remove(key, operation);
      if (!current()) return;
      _operations.remove(operation.id);
      _authorizations.remove(operation.id);
      _localBytes.remove(operation.id);
      final messages = _merge([canonical], state.messages);
      _emitOutboxState(
        state.copyWith(
          messages: messages,
          pending: state.pending
              .where((p) => p.clientMessageId != operation.id)
              .toList(),
        ),
      );
      _markNewestRead(messages);
      onChanged?.call();
    } catch (error) {
      if (current()) {
        if (_isAccessLost(error)) {
          await _loseAccess();
          return;
        }
        if (error is ApiException &&
            const [
              'CHAT_MEDIA_OBJECT_INVALID',
              'CHAT_MEDIA_OBJECT_MISSING',
              'CHAT_UPLOAD_EXPIRED',
            ].contains(error.code)) {
          // Explicit backend rejection is known not to have finalized this attempt.
          operation.submitted = false;
          try {
            if (operation.uploadId != null) {
              await _repository.cancelUpload(
                scope.workspaceId,
                group,
                operation.uploadId!,
              );
            }
          } catch (_) {}
          operation.uploadId = null;
          _authorizations.remove(operation.id);
        }
        operation.phase = 'failed';
        try {
          await outbox?.save(key, operation);
        } catch (_) {
          /* Durable prior phase remains recoverable. */
        }
        if (current()) {
          _showOperation(
            operation,
            failure: _failure(
              error,
              operation.submitted
                  ? 'Confirmation unavailable. Retry safely with the same message ID.'
                  : 'Unable to send media.',
            ),
          );
        }
      }
    } finally {
      _uploadCancellation = null;
      outbox?.coordinator.release();
    }
  }

  Future<void> cancelPending(String id) async {
    final operation = _operations[id];
    final key = _cacheScope;
    if (operation == null ||
        key == null ||
        operation.submitted ||
        !const ['queued', 'failed'].contains(operation.phase)) {
      return;
    }
    operation.phase = 'cancelled';
    if (operation.uploadId != null) {
      try {
        await _repository.cancelUpload(
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
    await outbox?.remove(key, operation);
    _operations.remove(id);
    _localBytes.remove(id);
    _authorizations.remove(id);
    if (!isClosed && _cacheScope?.key == key.key) {
      _emitOutboxState(
        state.copyWith(
          pending: state.pending.where((p) => p.clientMessageId != id).toList(),
        ),
      );
    }
  }

  void _cancelPendingForOldScope() {
    _uploadCancellation?.cancel();
    _operations.clear();
    _localBytes.clear();
    _authorizations.clear();
    // Preserve durable operations on route close. Never DELETE an uncertain finalized upload.
  }

  void _onAccessChanged() {
    final key = _cacheScope;
    if (key == null || outbox!.storage.authorized(key)) return;
    _cancelPendingForOldScope();
    _cancelRealtime();
    _generation++;
    _request++;
    if (!isClosed) {
      _emitOutboxState(
        const ChatConversationState(loading: false, accessLost: true),
      );
    }
  }

  Future<void> _loseAccess() async {
    final key = _cacheScope;
    _cancelPendingForOldScope();
    _cancelRealtime();
    if (!isClosed) {
      _emitOutboxState(
        const ChatConversationState(loading: false, accessLost: true),
      );
    }
    if (key != null) await outbox?.storage.revoke(key);
  }
}
