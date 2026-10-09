import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/entities/chat_outbox_operation.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_message_store.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_outbox_store.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/domain/services/chat_media_validation.dart';

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

enum ChatUploadState {
  queued,
  sending,
  uncertain,
  preparing,
  uploading,
  finalizing,
  sent,
  failed,
  cancelled,
}

enum PendingChatMediaType {
  text,
  location,
  image,
  voice;

  String get apiValue => switch (this) {
    PendingChatMediaType.text => 'TEXT',
    PendingChatMediaType.location => 'LOCATION',
    PendingChatMediaType.image => 'IMAGE',
    PendingChatMediaType.voice => 'VOICE',
  };
}

class PendingChatMessage extends Equatable {
  const PendingChatMessage({
    required this.clientMessageId,
    required this.mediaType,
    required this.status,
    this.progress = 0,
    this.previewBytes,
    this.durationMs,
    this.failure,
    this.text,
    this.location,
    this.localPath,
    this.canCancel = true,
  });

  final String clientMessageId;
  final PendingChatMediaType mediaType;
  final ChatUploadState status;
  final double progress;
  final Uint8List? previewBytes;
  final int? durationMs;
  final Failure? failure;
  final String? text;
  final ChatLocation? location;
  final String? localPath;
  final bool canCancel;

  PendingChatMessage copyWith({
    ChatUploadState? status,
    double? progress,
    bool clearPreview = false,
    Failure? failure,
    bool clearFailure = false,
  }) => PendingChatMessage(
    clientMessageId: clientMessageId,
    mediaType: mediaType,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    previewBytes: clearPreview ? null : previewBytes,
    durationMs: durationMs,
    failure: clearFailure ? null : failure ?? this.failure,
    text: text,
    location: location,
    localPath: localPath,
    canCancel: canCancel,
  );

  @override
  List<Object?> get props => [
    clientMessageId,
    mediaType,
    status,
    progress,
    previewBytes,
    durationMs,
    failure,
    text,
    location,
    localPath,
    canCancel,
  ];
}

class ChatConversationCubit extends Cubit<ChatConversationState> {
  ChatConversationCubit(
    this._repository,
    this._realtime, {
    this.onChanged,
    this.messageCache,
    this.outbox,
  }) : super(const ChatConversationState()) {
    outbox?.storage.listeners.add(_onAccessChanged);
  }
  final ChatMessageStore? messageCache;
  void _emitOutboxState(ChatConversationState value) => emit(value);
  final ChatOutboxStore? outbox;
  final ChatRepository _repository;
  final ChatRealtime _realtime;
  final void Function()? onChanged;
  FeatureSessionScope? _scope;
  String? _groupId;
  ChatRealtimeSubscription? _subscription;
  Timer? _refreshDebounce;
  var _generation = 0;
  var _request = 0;
  _ReadPosition? _confirmedReadPosition;
  _ReadPosition? _readInFlight;
  _ReadPosition? _pendingReadPosition;
  bool _synchronizingReadConflict = false;
  bool _loadingPage = false;
  bool _refreshQueued = false;
  final Map<String, ChatOutboxOperation> _operations = {};
  final Map<String, Uint8List> _localBytes = {};
  final Map<String, ChatUploadAuthorization> _authorizations = {};
  ChatUploadCancellation? _uploadCancellation;
  bool _outgoingRunning = false;
  bool _accepting = false;
  bool _cacheRestored = false;
  bool _latestLoaded = false;
  Set<String> _gapBoundaryIds = {};
  String? _historyCursor;
  ChatCacheScope? get _cacheScope => _scope == null || _groupId == null
      ? null
      : ChatCacheScope.fromSession(_scope!, _groupId!);

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
    _cacheRestored = false;
    _latestLoaded = false;
    _gapBoundaryIds = {};
    _historyCursor = null;
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
      final cacheScope = _cacheScope;
      if (!_cacheRestored && cacheScope != null && messageCache != null) {
        if (!messageCache!.storage.authorized(cacheScope)) {
          final group = await _repository.getGroup(scope.workspaceId, groupId);
          if (!_current(scope, groupId, generation, request)) return;
          if (group.id != groupId || group.workspaceId != scope.workspaceId) {
            throw const FormatException('Invalid group');
          }
          messageCache!.storage.grant(cacheScope, archived: group.isArchived);
        }
        final cached = await messageCache!.read(cacheScope);
        if (!_current(scope, groupId, generation, request)) return;
        _cacheRestored = true;
        _latestLoaded = cached?.messages.isNotEmpty == true;
        if (cached != null) {
          emit(
            state.copyWith(
              loading: false,
              messages: _merge(cached.messages, state.messages),
              nextCursor: cached.nextCursor,
              clearCursor: cached.nextCursor == null,
              refreshing: true,
            ),
          );
        }
        await _restoreOutbox();
        if (!_current(scope, groupId, generation, request)) return;
      }
      final page = await _repository.listMessages(scope.workspaceId, groupId);
      if (!_current(scope, groupId, generation, request)) return;
      _validate(page.messages, scope, groupId);
      try {
        await messageCache?.write(
          ChatCacheScope.fromSession(scope, groupId),
          page,
        );
      } catch (_) {
        /* Canonical rendering remains available if cache writes fail. */
      }
      if (!_current(scope, groupId, generation, request)) return;
      // Sends may finish while persistence awaits. Merge the current state only
      // after that await so a refresh cannot replace a newer confirmation.
      final currentMessages = state.messages;
      final overlaps =
          currentMessages.isEmpty ||
          page.messages.isEmpty ||
          page.messages.any(
            (m) => currentMessages.any((old) => old.id == m.id),
          );
      final merged = _merge(page.messages, currentMessages);
      if (!overlaps) {
        if (!state.historyGap) {
          _historyCursor = state.nextCursor;
          _gapBoundaryIds = currentMessages.map((m) => m.id).toSet();
        }
      }
      final cursor = !overlaps
          ? page.nextCursor
          : currentMessages.isNotEmpty && _latestLoaded
          ? state.nextCursor
          : page.nextCursor;
      emit(
        ChatConversationState(
          loading: false,
          messages: merged,
          nextCursor: cursor,
          pending: _withoutCanonicalPending(merged),
          historyGap: state.historyGap || !overlaps,
        ),
      );
      _latestLoaded = true;
      _markNewestRead(merged);
      unawaited(_drainOutgoing());
    } catch (error) {
      if (!_current(scope, groupId, generation, request)) return;
      final failure = _failure(error, 'Unable to load messages.');
      if (_isAccessLost(error)) {
        await _loseAccess();
        return;
      }
      emit(
        state.messages.isEmpty
            ? ChatConversationState(
                loading: false,
                failure: failure,
                pending: state.pending,
              )
            : state.copyWith(
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
      final cacheScope = ChatCacheScope.fromSession(scope, groupId);
      final cachedPage = await messageCache?.read(
        cacheScope,
        cursor: previous.nextCursor,
      );
      final page =
          cachedPage ??
          await _repository.listMessages(
            scope.workspaceId,
            groupId,
            cursor: previous.nextCursor,
          );
      if (!_current(scope, groupId, generation, request)) return;
      _validate(page.messages, scope, groupId);
      try {
        await messageCache?.write(
          cacheScope,
          page,
          cursor: previous.nextCursor,
        );
      } catch (_) {
        /* Older canonical pages still render if persistence is unavailable. */
      }
      if (!_current(scope, groupId, generation, request)) return;
      final merged = _merge(page.messages, state.messages);
      final gapClosed =
          state.historyGap &&
          (page.messages.any((m) => _gapBoundaryIds.contains(m.id)) ||
              page.nextCursor == null);
      final cursor = gapClosed ? _historyCursor : page.nextCursor;
      if (gapClosed) _gapBoundaryIds.clear();
      emit(
        state.copyWith(
          messages: merged,
          nextCursor: cursor,
          clearCursor: cursor == null,
          historyGap: state.historyGap && !gapClosed,
          loadingOlder: false,
          pending: _withoutCanonicalPending(merged),
        ),
      );
    } catch (error) {
      if (!_current(scope, groupId, generation, request)) return;
      if (_isAccessLost(error)) {
        await _loseAccess();
        return;
      }
      emit(
        state.copyWith(
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

  List<PendingChatMessage> _withoutCanonicalPending(
    List<ChatMessage> messages,
  ) {
    final canonicalClientIds = messages
        .map((message) => message.clientMessageId)
        .whereType<String>()
        .toSet();
    if (canonicalClientIds.isEmpty) return state.pending;
    for (final id in canonicalClientIds) {
      final operation = _operations.remove(id);
      _localBytes.remove(id);
      _authorizations.remove(id);
      if (operation != null && _cacheScope != null) {
        unawaited(
          outbox?.remove(_cacheScope!, operation) ?? Future<void>.value(),
        );
      }
    }
    return state.pending
        .where(
          (pending) => !canonicalClientIds.contains(pending.clientMessageId),
        )
        .toList(growable: false);
  }

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
    outbox?.storage.listeners.remove(_onAccessChanged);
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
