import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

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
    this.pending = const [],
    this.accessLost = false,
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
  ];
}

enum ChatUploadState {
  preparing,
  uploading,
  finalizing,
  sent,
  failed,
  cancelled,
}

class PendingChatMessage extends Equatable {
  const PendingChatMessage({
    required this.clientMessageId,
    required this.type,
    required this.status,
    this.progress = 0,
    this.previewBytes,
    this.durationMs,
    this.failure,
  });

  final String clientMessageId;
  final String type;
  final ChatUploadState status;
  final double progress;
  final Uint8List? previewBytes;
  final int? durationMs;
  final Failure? failure;

  PendingChatMessage copyWith({
    ChatUploadState? status,
    double? progress,
    bool clearPreview = false,
    Failure? failure,
    bool clearFailure = false,
  }) => PendingChatMessage(
    clientMessageId: clientMessageId,
    type: type,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    previewBytes: clearPreview ? null : previewBytes,
    durationMs: durationMs,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    clientMessageId,
    type,
    status,
    progress,
    previewBytes,
    durationMs,
    failure,
  ];
}

class _MediaJob {
  _MediaJob({
    required this.type,
    required this.mimeType,
    required this.bytes,
    this.durationMs,
  });
  final String type;
  final String mimeType;
  Uint8List? bytes;
  final int? durationMs;
  String? uploadId;
  ChatUploadCancellation? cancellation;
  bool running = false;
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
  _ReadPosition? _confirmedReadPosition;
  _ReadPosition? _readInFlight;
  _ReadPosition? _pendingReadPosition;
  bool _synchronizingReadConflict = false;
  bool _loadingPage = false;
  bool _refreshQueued = false;
  final Map<String, _MediaJob> _mediaJobs = {};

  void bind(FeatureSessionScope? scope, String groupId) {
    FeatureSessionScope? valid;
    try {
      valid = scope != null && chatOptionalUuid(groupId) != null ? scope : null;
    } on FormatException {
      valid = null;
    }
    if (_scope == valid && _groupId == groupId) return;
    _cancelPendingForOldScope();
    _cancelRealtime();
    _scope = valid;
    _groupId = valid == null ? null : groupId;
    _generation++;
    _request++;
    _pendingClientId = null;
    _pendingText = null;
    _clearReadState();
    _loadingPage = false;
    _refreshQueued = false;
    emit(const ChatConversationState());
    if (valid != null) {
      final subscriptionGeneration = _generation;
      _subscription = _realtime.subscribeToGroup(
        groupId,
        () => _onRealtimeInsert(subscriptionGeneration),
      );
      unawaited(load());
    }
  }

  Future<void> load({bool refresh = false}) async {
    final scope = _scope;
    final groupId = _groupId;
    if (scope == null || groupId == null) return;
    if (_loadingPage) {
      if (refresh) _refreshQueued = true;
      return;
    }
    _loadingPage = true;
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
          pending: state.pending,
        ),
      );
      _markNewestRead(merged);
    } catch (error) {
      if (!_current(scope, groupId, generation, request)) return;
      final failure = _failure(error, 'Unable to load messages.');
      if (_isAccessLost(error)) {
        _cancelRealtime();
        _cancelPendingForOldScope();
        emit(
          ChatConversationState(
            loading: false,
            failure: failure,
            accessLost: true,
          ),
        );
        return;
      }
      emit(
        previous.messages.isEmpty
            ? ChatConversationState(
                loading: false,
                failure: failure,
                pending: state.pending,
              )
            : previous.copyWith(
                refreshing: false,
                failure: failure,
                pending: state.pending,
              ),
      );
    } finally {
      if (_scopeCurrent(scope, groupId, generation)) {
        _loadingPage = false;
        if (_refreshQueued) {
          _refreshQueued = false;
          unawaited(load(refresh: true));
        }
      }
    }
  }

  Future<void> loadOlder() async {
    final scope = _scope;
    final groupId = _groupId;
    final previous = state;
    if (scope == null ||
        groupId == null ||
        previous.loadingOlder ||
        _loadingPage ||
        !previous.hasMore) {
      return;
    }
    final generation = _generation;
    _loadingPage = true;
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
          pending: state.pending,
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
    } finally {
      if (_scopeCurrent(scope, groupId, generation)) {
        _loadingPage = false;
        if (_refreshQueued) {
          _refreshQueued = false;
          unawaited(load(refresh: true));
        }
      }
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

  Future<String?> sendMedia({
    required String type,
    required String mimeType,
    required Uint8List bytes,
    int? durationMs,
  }) async {
    if (_scope == null ||
        _groupId == null ||
        !const ['IMAGE', 'VOICE'].contains(type) ||
        bytes.isEmpty) {
      return null;
    }
    final clientId = _uuidV4();
    _mediaJobs[clientId] = _MediaJob(
      type: type,
      mimeType: mimeType,
      bytes: bytes,
      durationMs: durationMs,
    );
    _replacePending(
      PendingChatMessage(
        clientMessageId: clientId,
        type: type,
        status: ChatUploadState.preparing,
        previewBytes: type == 'IMAGE' ? bytes : null,
        durationMs: durationMs,
      ),
    );
    unawaited(_runMedia(clientId));
    return clientId;
  }

  Future<void> retryMedia(String clientId) => _runMedia(clientId);

  Future<void> _runMedia(String clientId) async {
    final job = _mediaJobs[clientId];
    final scope = _scope;
    final groupId = _groupId;
    if (job == null || job.running || scope == null || groupId == null) return;
    job.running = true;
    final generation = _generation;
    try {
      if (job.uploadId == null) {
        final bytes = job.bytes;
        if (bytes == null) throw const FormatException('Media is unavailable');
        _updatePending(
          clientId,
          status: ChatUploadState.preparing,
          clearFailure: true,
        );
        final authorization = await _repository.initiateUpload(
          scope.workspaceId,
          groupId,
          type: job.type,
          mimeType: job.mimeType,
          sizeBytes: bytes.length,
          durationMs: job.durationMs,
        );
        if (!_scopeCurrent(scope, groupId, generation)) {
          unawaited(
            _repository.cancelUpload(
              scope.workspaceId,
              groupId,
              authorization.uploadId,
            ),
          );
          return;
        }
        job.uploadId = authorization.uploadId;
        _updatePending(
          clientId,
          status: ChatUploadState.uploading,
          progress: 0,
        );
        try {
          job.cancellation = ChatUploadCancellation();
          await _repository.uploadSigned(
            authorization,
            bytes,
            job.mimeType,
            onProgress: (sent, total) {
              if (_scopeCurrent(scope, groupId, generation) && total > 0) {
                _updatePending(clientId, progress: sent / total);
              }
            },
            cancellation: job.cancellation,
          );
        } catch (_) {
          await _cancelTracked(scope, groupId, job);
          rethrow;
        } finally {
          job.cancellation = null;
        }
      }
      if (!_scopeCurrent(scope, groupId, generation)) return;
      _updatePending(
        clientId,
        status: ChatUploadState.finalizing,
        progress: 1,
        clearPreview: true,
      );
      final canonical = await _repository.finalizeUpload(
        scope.workspaceId,
        groupId,
        type: job.type,
        uploadId: job.uploadId!,
        clientMessageId: clientId,
      );
      if (!_scopeCurrent(scope, groupId, generation)) return;
      _validate([canonical], scope, groupId);
      _mediaJobs.remove(clientId);
      job.bytes = null;
      final pending = state.pending
          .where((p) => p.clientMessageId != clientId)
          .toList();
      final messages = _merge([canonical], state.messages);
      emit(
        state.copyWith(
          messages: messages,
          pending: pending,
          clearFailure: true,
        ),
      );
      _markNewestRead(messages);
      onChanged?.call();
    } catch (error) {
      if (_scopeCurrent(scope, groupId, generation)) {
        if (error is ApiException &&
            const [
              'CHAT_UPLOAD_EXPIRED',
              'CHAT_UPLOAD_NOT_PENDING',
              'CHAT_MEDIA_OBJECT_MISSING',
              'CHAT_MEDIA_OBJECT_INVALID',
            ].contains(error.code)) {
          await _cancelTracked(scope, groupId, job);
        }
        _updatePending(
          clientId,
          status: ChatUploadState.failed,
          failure: _failure(error, 'Unable to send media.'),
        );
      }
    } finally {
      job.running = false;
    }
  }

  Future<void> cancelPending(String clientId) async {
    final job = _mediaJobs.remove(clientId);
    final scope = _scope;
    final groupId = _groupId;
    if (job != null && scope != null && groupId != null) {
      await _cancelTracked(scope, groupId, job);
      job.bytes = null;
    }
    if (!isClosed) {
      emit(
        state.copyWith(
          pending: state.pending
              .where((p) => p.clientMessageId != clientId)
              .toList(),
        ),
      );
    }
  }

  Future<bool> sendLocation(ChatLocation location) async {
    final scope = _scope;
    final groupId = _groupId;
    if (scope == null ||
        groupId == null ||
        !location.isValid ||
        state.sending) {
      return false;
    }
    final generation = _generation;
    emit(state.copyWith(sending: true, clearFailure: true));
    try {
      final canonical = await _repository.sendLocation(
        scope.workspaceId,
        groupId,
        location: location,
        clientMessageId: _uuidV4(),
      );
      if (!_scopeCurrent(scope, groupId, generation)) return false;
      _validate([canonical], scope, groupId);
      final messages = _merge([canonical], state.messages);
      emit(state.copyWith(sending: false, messages: messages));
      _markNewestRead(messages);
      onChanged?.call();
      return true;
    } catch (error) {
      if (_scopeCurrent(scope, groupId, generation)) {
        emit(
          state.copyWith(
            sending: false,
            failure: _failure(error, 'Unable to share location.'),
          ),
        );
      }
      return false;
    }
  }

  void _replacePending(PendingChatMessage value) {
    final pending = [...state.pending];
    final index = pending.indexWhere(
      (p) => p.clientMessageId == value.clientMessageId,
    );
    if (index < 0) {
      pending.add(value);
    } else {
      pending[index] = value;
    }
    emit(state.copyWith(pending: pending));
  }

  void _updatePending(
    String clientId, {
    ChatUploadState? status,
    double? progress,
    bool clearPreview = false,
    Failure? failure,
    bool clearFailure = false,
  }) {
    final current = state.pending
        .where((p) => p.clientMessageId == clientId)
        .firstOrNull;
    if (current == null) return;
    _replacePending(
      current.copyWith(
        status: status,
        progress: progress,
        clearPreview: clearPreview,
        failure: failure,
        clearFailure: clearFailure,
      ),
    );
  }

  Future<void> _cancelTracked(
    FeatureSessionScope scope,
    String groupId,
    _MediaJob job,
  ) async {
    job.cancellation?.cancel();
    job.cancellation = null;
    final uploadId = job.uploadId;
    job.uploadId = null;
    if (uploadId == null) return;
    try {
      await _repository.cancelUpload(scope.workspaceId, groupId, uploadId);
    } catch (_) {
      // Cancellation is best-effort; backend expiry cleanup remains authoritative.
    }
  }

  void _cancelPendingForOldScope() {
    final scope = _scope;
    final groupId = _groupId;
    final jobs = _mediaJobs.values.toList();
    _mediaJobs.clear();
    for (final job in jobs) {
      job.bytes = null;
      if (scope != null && groupId != null) {
        unawaited(_cancelTracked(scope, groupId, job));
      }
    }
  }

  void _onRealtimeInsert(int generation) {
    if (generation != _generation) return;
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!isClosed && generation == _generation) {
        unawaited(load(refresh: true));
      }
    });
  }

  void _markNewestRead(List<ChatMessage> messages) {
    if (messages.isEmpty) return;
    final newest = messages.reduce(
      (current, candidate) =>
          _ReadPosition.fromMessage(candidate)
                  .compareTo(_ReadPosition.fromMessage(current)) >
              0
          ? candidate
          : current,
    );
    _queueRead(_ReadPosition.fromMessage(newest));
  }

  void _queueRead(_ReadPosition position) {
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
    final scope = _scope;
    final groupId = _groupId;
    final generation = _generation;
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
    _ReadPosition requested, {
    required bool allowConflictSync,
  }) async {
    var synchronized = false;
    try {
      await _repository.markRead(
        scope.workspaceId,
        groupId,
        requested.messageId,
      );
      if (!_readRequestCurrent(scope, groupId, generation, requested)) return;
      _confirmedReadPosition = _newer(_confirmedReadPosition, requested);
      onChanged?.call();
    } catch (error) {
      if (!_readRequestCurrent(scope, groupId, generation, requested)) return;
      if (error is ApiException &&
          error.code == 'CHAT_READ_POSITION_BACKWARDS') {
        _confirmedReadPosition = _newer(_confirmedReadPosition, requested);
        onChanged?.call();
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
    if (!_scopeCurrent(scope, groupId, generation)) return;
    if (synchronized) {
      _synchronizingReadConflict = true;
      await load(refresh: true);
      if (!_scopeCurrent(scope, groupId, generation)) return;
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
    _ReadPosition requested,
  ) => _scopeCurrent(scope, groupId, generation) && _readInFlight == requested;

  _ReadPosition _newer(_ReadPosition? first, _ReadPosition second) =>
      first == null || second.compareTo(first) > 0 ? second : first;

  void _clearReadState() {
    _confirmedReadPosition = null;
    _readInFlight = null;
    _pendingReadPosition = null;
    _synchronizingReadConflict = false;
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
  bool _isAccessLost(Object error) =>
      error is ApiException &&
      (error.statusCode == 403 ||
          (error.statusCode == 404 && error.code == 'CHAT_GROUP_NOT_FOUND'));
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
    _cancelPendingForOldScope();
    _generation++;
    _request++;
    _scope = null;
    _groupId = null;
    _loadingPage = false;
    _refreshQueued = false;
    _clearReadState();
    _refreshDebounce?.cancel();
    _refreshDebounce = null;
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
    return super.close();
  }
}

class _ReadPosition implements Comparable<_ReadPosition> {
  const _ReadPosition(this.createdAt, this.messageId);

  factory _ReadPosition.fromMessage(ChatMessage message) =>
      _ReadPosition(message.createdAt.toUtc(), message.id);

  final DateTime createdAt;
  final String messageId;

  @override
  int compareTo(_ReadPosition other) {
    final byTime = createdAt.compareTo(other.createdAt);
    return byTime == 0 ? messageId.compareTo(other.messageId) : byTime;
  }

  @override
  bool operator ==(Object other) =>
      other is _ReadPosition &&
      createdAt == other.createdAt &&
      messageId == other.messageId;

  @override
  int get hashCode => Object.hash(createdAt, messageId);
}

String _uuidV4() {
  final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final value = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
      '${value.substring(12, 16)}-${value.substring(16, 20)}-${value.substring(20)}';
}
