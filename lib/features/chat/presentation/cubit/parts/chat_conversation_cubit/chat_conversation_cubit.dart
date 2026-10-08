part of '../../chat_conversation_cubit.dart';

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
  final ChatMessageCache? messageCache;
  void _emitOutboxState(ChatConversationState value) => emit(value);
  final ChatOutboxStorage? outbox;
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
              messages: _chronological(cached.messages),
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
      try {
        await messageCache?.write(
          ChatCacheScope.fromSession(scope, groupId),
          page,
        );
      } catch (_) {
        /* Canonical rendering remains available if cache writes fail. */
      }
      if (!_current(scope, groupId, generation, request)) return;
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
