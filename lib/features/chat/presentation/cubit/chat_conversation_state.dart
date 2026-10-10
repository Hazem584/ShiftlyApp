import 'package:equatable/equatable.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

import 'pending_chat_message.dart';

class ChatConversationState extends Equatable {
  const ChatConversationState({
    this.loading = true,
    this.messages = const [],
    this.nextCursor,
    this.loadingOlder = false,
    this.refreshing = false,
    this.sending = false,
    this.failedText,
    this.failure,
    this.pending = const [],
    this.accessLost = false,
    this.historyGap = false,
  });
  final bool loading;
  final List<ChatMessage> messages;
  final String? nextCursor;
  final bool loadingOlder;
  final bool refreshing;
  final bool sending;
  final String? failedText;
  final Failure? failure;
  final List<PendingChatMessage> pending;
  final bool accessLost;
  final bool historyGap;
  bool get hasMore => nextCursor != null;

  ChatConversationState copyWith({
    bool? loading,
    List<ChatMessage>? messages,
    String? nextCursor,
    bool clearCursor = false,
    bool? loadingOlder,
    bool? refreshing,
    bool? sending,
    String? failedText,
    bool clearFailedText = false,
    Failure? failure,
    bool clearFailure = false,
    List<PendingChatMessage>? pending,
    bool? accessLost,
    bool? historyGap,
  }) => ChatConversationState(
    loading: loading ?? this.loading,
    messages: messages ?? this.messages,
    nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
    loadingOlder: loadingOlder ?? this.loadingOlder,
    refreshing: refreshing ?? this.refreshing,
    sending: sending ?? this.sending,
    failedText: clearFailedText ? null : failedText ?? this.failedText,
    failure: clearFailure ? null : failure ?? this.failure,
    pending: pending ?? this.pending,
    accessLost: accessLost ?? this.accessLost,
    historyGap: historyGap ?? this.historyGap,
  );

  @override
  List<Object?> get props => [
    loading,
    messages,
    nextCursor,
    loadingOlder,
    refreshing,
    sending,
    failedText,
    failure,
    pending,
    accessLost,
    historyGap,
  ];
}
