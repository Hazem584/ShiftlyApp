import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_message_store.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_outbox_store.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';

import 'chat_conversation_host.dart';
import 'chat_conversation_state.dart';
import 'chat_outbox_controller.dart';
import 'chat_read_receipts.dart';

export 'chat_conversation_state.dart';
export 'pending_chat_message.dart';

class ChatConversationCubit extends Cubit<ChatConversationState>
    implements ChatConversationHost {
  ChatConversationCubit(
    this._repository,
    this._realtime, {
    this.onChanged,
    this.messageCache,
    this.outbox,
  }) : super(const ChatConversationState()) {
    outbox?.storage.listeners.add(_onAccessChanged);
  }
  @override
  final ChatMessageStore? messageCache;

  @override
  final ChatOutboxStore? outbox;
  final ChatRepository _repository;
  final ChatRealtime _realtime;
  @override
  final void Function()? onChanged;
  FeatureSessionScope? _scope;
  String? _groupId;
  ChatRealtimeSubscription? _subscription;
  Timer? _refreshDebounce;
  var _generation = 0;
  var _request = 0;

  bool _loadingPage = false;
  bool _refreshQueued = false;

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
    _outgoing.clear();
    _cancelRealtime();
    _scope = valid;
    _groupId = valid == null ? null : groupId;
    _generation++;
    _request++;
    _cacheRestored = false;
    _latestLoaded = false;
    _gapBoundaryIds = {};
    _historyCursor = null;
    _reads.clear();
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

  @override
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
        await _outgoing.restore();
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
          pending: _outgoing.withoutCanonicalPending(merged),
          historyGap: state.historyGap || !overlaps,
        ),
      );
      _latestLoaded = true;
      _reads.markNewestRead(merged);
      unawaited(_outgoing.drain());
    } catch (error) {
      if (!_current(scope, groupId, generation, request)) return;
      final failure = _failure(error, 'Unable to load messages.');
      if (_isAccessLost(error)) {
        await loseAccess();
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
          pending: _outgoing.withoutCanonicalPending(merged),
        ),
      );
    } catch (error) {
      if (!_current(scope, groupId, generation, request)) return;
      if (_isAccessLost(error)) {
        await loseAccess();
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
    outbox?.storage.listeners.remove(_onAccessChanged);
    _outgoing.clear();
    _generation++;
    _request++;
    _scope = null;
    _groupId = null;
    _loadingPage = false;
    _refreshQueued = false;
    _reads.clear();
    _refreshDebounce?.cancel();
    _refreshDebounce = null;
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
    return super.close();
  }

  late final _reads = ChatReadReceipts(this);
  late final _outgoing = ChatOutboxController(this);
  @override
  FeatureSessionScope? get scope => _scope;
  @override
  String? get groupId => _groupId;
  @override
  int get generation => _generation;
  @override
  ChatCacheScope? get cacheScope => _cacheScope;
  @override
  ChatRepository get repository => _repository;
  @override
  void emitState(ChatConversationState value) => emit(value);
  @override
  bool scopeCurrent(
    FeatureSessionScope scope,
    String groupId,
    int generation,
  ) => _scopeCurrent(scope, groupId, generation);
  @override
  void validateMessages(
    List<ChatMessage> values,
    FeatureSessionScope scope,
    String groupId,
  ) => _validate(values, scope, groupId);
  @override
  List<ChatMessage> mergeMessages(
    List<ChatMessage> incoming,
    List<ChatMessage> current,
  ) => _merge(incoming, current);
  @override
  void markNewestRead(List<ChatMessage> messages) =>
      _reads.markNewestRead(messages);
  Future<bool> send(String value) => _outgoing.send(value);
  Future<bool> retrySend() => _outgoing.retrySend();
  Future<String?> sendImage(Uint8List bytes) => _outgoing.sendImage(bytes);
  Future<String?> sendVoice({
    required Uint8List bytes,
    required String mimeType,
    required int durationMs,
  }) => _outgoing.sendVoice(
    bytes: bytes,
    mimeType: mimeType,
    durationMs: durationMs,
  );
  Future<bool> sendLocation(ChatLocation location) =>
      _outgoing.sendLocation(location);
  Future<void> retryMedia(String id) => _outgoing.retryMedia(id);
  Future<void> cancelPending(String id) => _outgoing.cancelPending(id);

  void _onAccessChanged() {
    final key = _cacheScope;
    if (key == null || outbox!.storage.authorized(key)) return;
    _outgoing.clear();
    _cancelRealtime();
    _generation++;
    _request++;
    if (!isClosed) {
      emit(const ChatConversationState(loading: false, accessLost: true));
    }
  }

  @override
  Future<void> loseAccess() async {
    final key = _cacheScope;
    _outgoing.clear();
    _cancelRealtime();
    if (!isClosed) {
      emit(const ChatConversationState(loading: false, accessLost: true));
    }
    if (key != null) await outbox?.storage.revoke(key);
  }
}
