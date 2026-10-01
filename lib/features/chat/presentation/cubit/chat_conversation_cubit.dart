import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/data/chat_models.dart';
import 'package:shiftly/features/chat/data/chat_realtime.dart';
import 'package:shiftly/features/chat/data/chat_repository.dart';

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
  });
  final bool loading;
  final List<ChatMessage> messages;
  final String? nextCursor;
  final bool loadingOlder;
  final bool refreshing;
  final bool sending;
  final String? failedText;
  final Failure? failure;
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
  }) => ChatConversationState(
    loading: loading ?? this.loading,
    messages: messages ?? this.messages,
    nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
    loadingOlder: loadingOlder ?? this.loadingOlder,
    refreshing: refreshing ?? this.refreshing,
    sending: sending ?? this.sending,
    failedText: clearFailedText ? null : failedText ?? this.failedText,
    failure: clearFailure ? null : failure ?? this.failure,
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
  ];
}

class ChatConversationCubit extends Cubit<ChatConversationState> {
  ChatConversationCubit(this._repository, this._realtime, {this.onChanged})
    : super(const ChatConversationState());
  final ChatRepository _repository;
  final ChatRealtime _realtime;
  final void Function()? onChanged;
  FeatureSessionScope? _scope;
  String? _groupId;
  ChatRealtimeSubscription? _subscription;
  Timer? _refreshDebounce;
  var _generation = 0;
  var _request = 0;
  String? _pendingClientId;
  String? _pendingText;
  DateTime? _readAt;

  void bind(FeatureSessionScope? scope, String groupId) {
    FeatureSessionScope? valid;
    try {
      valid = scope != null && chatOptionalUuid(groupId) != null ? scope : null;
    } on FormatException {
      valid = null;
    }
    if (_scope == valid && _groupId == groupId) return;
    _cancelRealtime();
    _scope = valid;
    _groupId = valid == null ? null : groupId;
    _generation++;
    _request++;
    _pendingClientId = null;
    _pendingText = null;
    _readAt = null;
    emit(const ChatConversationState());
    if (valid != null) {
      _subscription = _realtime.subscribeToGroup(groupId, _onRealtimeInsert);
      unawaited(load());
    }
  }

  Future<void> load({bool refresh = false}) async {
    final scope = _scope;
    final groupId = _groupId;
    if (scope == null || groupId == null) return;
    final generation = _generation;
    final request = ++_request;
    final previous = state;
    if (refresh && previous.messages.isNotEmpty) {
      emit(previous.copyWith(refreshing: true, clearFailure: true));
    }
    try {
      final page = await _repository.listMessages(scope.workspaceId, groupId);
      if (!_current(scope, groupId, generation, request)) return;
      _validate(page.messages, scope, groupId);
      final merged = refresh
          ? _merge(page.messages, previous.messages)
          : _chronological(page.messages);
      emit(
        ChatConversationState(
          loading: false,
          messages: merged,
          nextCursor: page.nextCursor,
        ),
      );
      _markNewestRead(merged);
      onChanged?.call();
    } catch (error) {
      if (!_current(scope, groupId, generation, request)) return;
      final failure = _failure(error, 'Unable to load messages.');
      emit(
        previous.messages.isEmpty
            ? ChatConversationState(loading: false, failure: failure)
            : previous.copyWith(refreshing: false, failure: failure),
      );
    }
  }

  Future<void> loadOlder() async {
    final scope = _scope;
    final groupId = _groupId;
    final previous = state;
    if (scope == null ||
        groupId == null ||
        previous.loadingOlder ||
        !previous.hasMore) {
      return;
    }
    final generation = _generation;
    final request = ++_request;
    emit(previous.copyWith(loadingOlder: true, clearFailure: true));
    try {
      final page = await _repository.listMessages(
        scope.workspaceId,
        groupId,
        cursor: previous.nextCursor,
      );
      if (!_current(scope, groupId, generation, request)) return;
      _validate(page.messages, scope, groupId);
      emit(
        previous.copyWith(
          messages: _merge(page.messages, previous.messages),
          nextCursor: page.nextCursor,
          clearCursor: page.nextCursor == null,
          loadingOlder: false,
        ),
      );
    } catch (error) {
      if (!_current(scope, groupId, generation, request)) return;
      emit(
        previous.copyWith(
          loadingOlder: false,
          failure: _failure(error, 'Unable to load older messages.'),
        ),
      );
    }
  }

  Future<bool> send(String value) async {
    final text = value.trim();
    if (text.isEmpty || text.length > 4000 || state.sending) return false;
    _pendingText = text;
    _pendingClientId = _uuidV4();
    return _sendPending();
  }

  Future<bool> retrySend() async {
    if (_pendingText == null || _pendingClientId == null || state.sending) {
      return false;
    }
    return _sendPending();
  }

  Future<bool> _sendPending() async {
    final scope = _scope;
    final groupId = _groupId;
    final text = _pendingText;
    final clientId = _pendingClientId;
    if (scope == null || groupId == null || text == null || clientId == null) {
      return false;
    }
    final generation = _generation;
    emit(
      state.copyWith(sending: true, clearFailure: true, clearFailedText: true),
    );
    try {
      final message = await _repository.sendMessage(
        scope.workspaceId,
        groupId,
        text: text,
        clientMessageId: clientId,
      );
      if (!_scopeCurrent(scope, groupId, generation)) return false;
      _validate([message], scope, groupId);
      _pendingText = null;
      _pendingClientId = null;
      final messages = _merge([message], state.messages);
      emit(
        state.copyWith(
          sending: false,
          messages: messages,
          clearFailedText: true,
        ),
      );
      _markNewestRead(messages);
      onChanged?.call();
      return true;
    } catch (error) {
      if (!_scopeCurrent(scope, groupId, generation)) return false;
      emit(
        state.copyWith(
          sending: false,
          failedText: text,
          failure: _failure(error, 'Unable to send the message.'),
        ),
      );
      return false;
    }
  }

  void _onRealtimeInsert() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!isClosed) unawaited(load(refresh: true));
    });
  }

  void _markNewestRead(List<ChatMessage> messages) {
    if (messages.isEmpty) return;
    final newest = messages.last;
    if (_readAt != null && !newest.createdAt.isAfter(_readAt!)) return;
    _readAt = newest.createdAt;
    final scope = _scope;
    final groupId = _groupId;
    final generation = _generation;
    if (scope == null || groupId == null) return;
    unawaited(
      _repository
          .markRead(scope.workspaceId, groupId, newest.id)
          .then((_) {
            if (_scopeCurrent(scope, groupId, generation)) onChanged?.call();
          })
          .catchError((_) {}),
    );
  }

  List<ChatMessage> _merge(
    List<ChatMessage> incoming,
    List<ChatMessage> current,
  ) {
    final byId = <String, ChatMessage>{
      for (final item in current) item.id: item,
    };
    for (final item in incoming) {
      byId[item.id] = item;
    }
    return _chronological(byId.values.toList());
  }

  List<ChatMessage> _chronological(List<ChatMessage> values) =>
      [...values]..sort((a, b) {
        final byTime = a.createdAt.compareTo(b.createdAt);
        return byTime == 0 ? a.id.compareTo(b.id) : byTime;
      });

  void _validate(
    List<ChatMessage> values,
    FeatureSessionScope scope,
    String groupId,
  ) {
    if (values.any((item) => item.groupId != groupId)) {
      throw const FormatException('Cross-group message response');
    }
  }

  Failure _failure(Object error, String fallback) => error is ApiException
      ? error.toFailure()
      : Failure(message: fallback, kind: FailureKind.server);
  bool _current(
    FeatureSessionScope scope,
    String groupId,
    int generation,
    int request,
  ) => _scopeCurrent(scope, groupId, generation) && _request == request;
  bool _scopeCurrent(
    FeatureSessionScope scope,
    String groupId,
    int generation,
  ) =>
      !isClosed &&
      _scope == scope &&
      _groupId == groupId &&
      _generation == generation;

  void _cancelRealtime() {
    _refreshDebounce?.cancel();
    _refreshDebounce = null;
    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) unawaited(subscription.cancel());
  }

  @override
  Future<void> close() async {
    _refreshDebounce?.cancel();
    await _subscription?.cancel();
    return super.close();
  }
}

String _uuidV4() {
  final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final value = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
      '${value.substring(12, 16)}-${value.substring(16, 20)}-${value.substring(20)}';
}
