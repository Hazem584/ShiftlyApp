import 'dart:async';

import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/entities/chat_outbox_operation.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';

import 'chat_conversation_host.dart';
import 'chat_outbox_queue.dart';

class ChatMessageDelivery {
  ChatMessageDelivery(this.host, this.queue, this.showOperation);
  final ChatConversationHost host;
  final ChatOutboxQueue queue;
  final void Function(ChatOutboxOperation, {Failure? failure}) showOperation;
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

  Future<void> submit(ChatOutboxOperation operation, int generation) async {
    final scope = host.scope;
    final group = host.groupId;
    final key = host.cacheScope;
    if (scope == null || group == null || key == null) return;
    bool current() =>
        host.scopeCurrent(scope, group, generation) &&
        queue.operations[operation.id] == operation &&
        (host.outbox == null || host.outbox!.storage.writable(key));
    Future<void> phase(String value, {bool submitted = false}) async {
      if (!current()) throw StateError('Chat access unavailable');
      operation.phase = value;
      operation.submitted = operation.submitted || submitted;
      await host.outbox?.save(key, operation);
      if (!current()) throw StateError('Chat access unavailable');
      showOperation(operation);
    }

    final lightweight =
        operation.type == 'TEXT' || operation.type == 'LOCATION';
    await host.outbox?.coordinator.acquire(lightweight: lightweight);
    final confirmation = Completer<void>();
    queue.confirmations[operation.id] = confirmation;
    Future<ChatMessage?> acknowledged(Future<ChatMessage> response) =>
        Future.any<ChatMessage?>([
          response,
          confirmation.future.then((_) => null),
        ]);
    try {
      if (!current()) return;
      ChatMessage? canonical;
      if (operation.type == 'TEXT' || operation.type == 'LOCATION') {
        await phase('sending', submitted: true);
        canonical = await acknowledged(
          operation.type == 'TEXT'
              ? _retryIdempotent(
                  () => host.repository.sendMessage(
                    scope.workspaceId,
                    group,
                    text: operation.text!,
                    replyToMessageId: operation.replyToMessageId,
                    clientMessageId: operation.id,
                  ),
                  current,
                )
              : _retryIdempotent(
                  () => host.repository.sendLocation(
                    scope.workspaceId,
                    group,
                    location: operation.location!,
                    clientMessageId: operation.id,
                  ),
                  current,
                ),
        );
      } else {
        if (!operation.submitted) {
          await phase('preparing');
          // A restarted interrupted PUT has no persisted signed authorization. Cancel only this never-finalized upload.
          if (operation.uploadId != null &&
              !queue.authorizations.containsKey(operation.id)) {
            await host.repository.cancelUpload(
              scope.workspaceId,
              group,
              operation.uploadId!,
            );
            operation.uploadId = null;
          }
          var authorization = queue.authorizations[operation.id];
          if (authorization == null ||
              !authorization.expiresAt.isAfter(DateTime.now().toUtc())) {
            if (authorization != null) {
              await host.repository.cancelUpload(
                scope.workspaceId,
                group,
                authorization.uploadId,
              );
            }
            authorization = await host.repository.initiateUpload(
              scope.workspaceId,
              group,
              type: operation.type,
              mimeType: operation.mimeType!,
              sizeBytes: operation.sizeBytes!,
              durationMs: operation.durationMs,
              fileName: operation.fileName,
            );
            if (!current()) return;
            operation.uploadId = authorization.uploadId;
            queue.authorizations[operation.id] = authorization;
            await host.outbox?.save(key, operation);
          }
          await phase('uploading');
          final bytes =
              queue.localBytes[operation.id] ??
              await host.outbox!.mediaFile(operation.file!).readAsBytes();
          if (!current()) return;
          queue.uploadCancellation = ChatUploadCancellation();
          try {
            await host.repository.uploadSigned(
              authorization,
              bytes,
              operation.mimeType!,
              cancellation: queue.uploadCancellation,
              onProgress: (sent, total) {
                if (current() && total > 0) {
                  final pending = host.state.pending
                      .where((p) => p.clientMessageId == operation.id)
                      .firstOrNull;
                  if (pending != null) {
                    host.emitState(
                      host.state.copyWith(
                        pending: host.state.pending
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
                await host.repository.cancelUpload(
                  scope.workspaceId,
                  group,
                  authorization.uploadId,
                );
              } catch (_) {}
              operation.uploadId = null;
              queue.authorizations.remove(operation.id);
            }
            rethrow;
          }
        }
        await phase('finalizing', submitted: true);
        canonical = await acknowledged(
          _retryIdempotent(
            () => host.repository.finalizeUpload(
              scope.workspaceId,
              group,
              type: operation.type,
              uploadId: operation.uploadId!,
              clientMessageId: operation.id,
            ),
            current,
          ),
        );
      }
      if (canonical == null || !current()) return;
      host.validateMessages([canonical], scope, group);
      if (canonical.clientMessageId != operation.id ||
          canonical.type != operation.type) {
        throw const FormatException('Invalid confirmation');
      }
      final messages = host.mergeMessages([canonical], host.state.messages);
      host.emitState(
        host.state.copyWith(
          messages: messages,
          pending: host.state.pending
              .where((p) => p.clientMessageId != operation.id)
              .toList(),
        ),
      );
      host.markNewestRead(messages);
      host.onChanged?.call();
      queue.operations.remove(operation.id);
      queue.authorizations.remove(operation.id);
      queue.localBytes.remove(operation.id);
      final saved = canonical;
      // Persistence is recoverable using the same UUID. It must not hold the
      // network lane after canonical server acknowledgement.
      final persistence = () async {
        try {
          await host.messageCache?.confirm(key, saved);
        } catch (_) {
          /* canonical delivery survives unavailable cache */
        }
        if (!host.scopeCurrent(scope, group, generation)) return;
        try {
          await host.outbox?.remove(key, operation);
        } catch (_) {
          /* reconcile retained UUID on restart */
        }
      }();
      if (lightweight) {
        unawaited(persistence);
      } else {
        await persistence;
      }
    } catch (error) {
      if (current()) {
        if (_isAccessLost(error)) {
          await host.loseAccess();
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
              await host.repository.cancelUpload(
                scope.workspaceId,
                group,
                operation.uploadId!,
              );
            }
          } catch (_) {}
          operation.uploadId = null;
          queue.authorizations.remove(operation.id);
        }
        operation.phase = 'failed';
        try {
          await host.outbox?.save(key, operation);
        } catch (_) {
          /* Durable prior phase remains recoverable. */
        }
        if (current()) {
          showOperation(
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
      if (identical(queue.confirmations[operation.id], confirmation)) {
        queue.confirmations.remove(operation.id);
      }
      if (!lightweight) queue.uploadCancellation = null;
      host.outbox?.coordinator.release(lightweight: lightweight);
    }
  }

  Failure _failure(Object error, String fallback) => error is ApiException
      ? error.toFailure()
      : Failure(message: fallback, kind: FailureKind.server);
  bool _isAccessLost(Object error) =>
      error is ApiException &&
      (error.statusCode == 403 ||
          (error.statusCode == 404 && error.code == 'CHAT_GROUP_NOT_FOUND'));
}
