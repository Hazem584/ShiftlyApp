part of '../../chat_conversation_cubit.dart';

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
          pending: _withoutCanonicalPending(merged),
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
          pending: _withoutCanonicalPending(
            _merge(page.messages, previous.messages),
          ),
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

  Future<String?> sendImage(Uint8List bytes) async {
    final ownedBytes = Uint8List.fromList(bytes);
    final mimeType = ChatMediaValidation.imageMime(ownedBytes);
    if (mimeType == null) return null;
    return _createMediaJob(
      mediaType: PendingChatMediaType.image,
      mimeType: mimeType,
      bytes: ownedBytes,
    );
  }

  Future<String?> sendVoice({
    required Uint8List bytes,
    required String mimeType,
    required int durationMs,
  }) async {
    final ownedBytes = Uint8List.fromList(bytes);
    if (!ChatMediaValidation.validVoice(
      bytes: ownedBytes,
      mimeType: mimeType,
      durationMs: durationMs,
    )) {
      return null;
    }
    return _createMediaJob(
      mediaType: PendingChatMediaType.voice,
      mimeType: mimeType,
      bytes: ownedBytes,
      durationMs: durationMs,
    );
  }

  String? _createMediaJob({
    required PendingChatMediaType mediaType,
    required String mimeType,
    required Uint8List bytes,
    int? durationMs,
  }) {
    if (_scope == null || _groupId == null) return null;
    final clientId = _uuidV4();
    final job = _MediaJob(
      clientMessageId: clientId,
      mediaType: mediaType,
      mimeType: mimeType,
      bytes: bytes,
      sizeBytes: bytes.length,
      previewBytes: mediaType == PendingChatMediaType.image
          ? Uint8List.fromList(bytes)
          : null,
      durationMs: durationMs,
    );
    _mediaJobs[clientId] = job;
    _replacePending(
      PendingChatMessage(
        clientMessageId: clientId,
        mediaType: mediaType,
        status: ChatUploadState.preparing,
        previewBytes: job.previewBytes,
        durationMs: mediaType == PendingChatMediaType.voice ? durationMs : null,
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
      final existingAuthorization = job.authorization;
      if (existingAuthorization != null &&
          !existingAuthorization.expiresAt.isAfter(DateTime.now().toUtc())) {
        await _cancelTracked(scope, groupId, job);
      }
      if (job.authorization == null) {
        _updatePending(
          clientId,
          status: ChatUploadState.preparing,
          clearFailure: true,
        );
        final authorization = await _repository.initiateUpload(
          scope.workspaceId,
          groupId,
          type: job.mediaType.apiValue,
          mimeType: job.mimeType,
          sizeBytes: job.sizeBytes,
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
        job.authorization = authorization;
        job.uploaded = false;
      }
      if (!job.uploaded) {
        final authorization = job.authorization!;
        _updatePending(
          clientId,
          status: ChatUploadState.uploading,
          progress: 0,
        );
        try {
          job.cancellation = ChatUploadCancellation();
          await _repository.uploadSigned(
            authorization,
            job.bytes,
            job.mimeType,
            onProgress: (sent, total) {
              if (_scopeCurrent(scope, groupId, generation) && total > 0) {
                _updatePending(clientId, progress: sent / total);
              }
            },
            cancellation: job.cancellation,
          );
          job.uploaded = true;
        } catch (_) {
          await _cancelTracked(scope, groupId, job);
          rethrow;
        } finally {
          job.cancellation = null;
        }
      }
      if (!_scopeCurrent(scope, groupId, generation)) return;
      _updatePending(clientId, status: ChatUploadState.finalizing, progress: 1);
      final canonical = await _repository.finalizeUpload(
        scope.workspaceId,
        groupId,
        type: job.mediaType.apiValue,
        uploadId: job.authorization!.uploadId,
        clientMessageId: clientId,
      );
      if (!_scopeCurrent(scope, groupId, generation)) return;
      _validate([canonical], scope, groupId);
      if (canonical.clientMessageId != job.clientMessageId ||
          canonical.type != job.mediaType.apiValue) {
        throw const FormatException('Mismatched canonical media message');
      }
      _mediaJobs.remove(clientId);
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
    final uploadId = job.authorization?.uploadId;
    job.authorization = null;
    job.uploaded = false;
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

  List<PendingChatMessage> _withoutCanonicalPending(
    List<ChatMessage> messages,
  ) {
    final canonicalClientIds = messages
        .map((message) => message.clientMessageId)
        .whereType<String>()
        .toSet();
    if (canonicalClientIds.isEmpty) return state.pending;
    for (final id in canonicalClientIds) {
      _mediaJobs.remove(id)?.cancellation?.cancel();
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
