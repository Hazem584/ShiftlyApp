import 'dart:async';

import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/entities/chat_outbox_operation.dart';

import 'chat_message_delivery.dart';

Future<T> retryChatIdempotent<T>(
  Future<T> Function() submit,
  bool Function() current,
) async {
  try {
    return await submit();
  } on ApiException catch (error) {
    final retryable = error.kind == FailureKind.network ||
        error.kind == FailureKind.timeout ||
        (error.statusCode ?? 0) >= 500;
    if (!retryable || !current()) rethrow;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!current()) throw StateError('Chat access unavailable');
    return submit();
  }
}

Future<void> commitDeliveredChatMessage(
  ChatMessageDelivery delivery,
  ChatOutboxOperation operation,
  ChatMessage canonical,
  int generation,
  bool lightweight,
) async {
  final host = delivery.host, queue = delivery.queue;
  final scope = host.scope!, group = host.groupId!, key = host.cacheScope!;
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
  final persistence = () async {
    try {
      await host.messageCache?.confirm(key, canonical);
    } catch (_) {}
    if (!host.scopeCurrent(scope, group, generation)) return;
    try {
      await host.outbox?.remove(key, operation);
    } catch (_) {}
  }();
  if (lightweight) {
    unawaited(persistence);
  } else {
    await persistence;
  }
}
