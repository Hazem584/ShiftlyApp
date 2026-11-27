import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_cache_access.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_group_details_state.dart';

abstract class ChatGroupDetailsSession extends Cubit<ChatGroupDetailsState> {
  ChatGroupDetailsSession(
    this.repository, {
    this.onChanged,
    this.loadGroup,
    this.cacheDatabase,
    this.realtime,
  }) : super(const ChatGroupDetailsState());
  final ChatRealtime? realtime;
  ChatRealtimeSubscription? _subscription;
  final ChatRepository repository;
  final ChatCacheAccess? cacheDatabase;
  final void Function()? onChanged;
  final Future<ChatGroup> Function()? loadGroup;
  FeatureSessionScope? _scope;
  String? _groupId;
  int _generation = 0;
  FeatureSessionScope? get scope => _scope;
  String? get groupId => _groupId;
  int get generation => _generation;
  bool loadingDetails = false;

  Future<void> load();

  void bind(
    FeatureSessionScope scope,
    String groupId, {
    ChatGroup? initialGroup,
  }) {
    if (_scope == scope && _groupId == groupId) return;
    unawaited(_subscription?.cancel());
    final source = realtime;
    _subscription = source is ChatGroupStateRealtime
        ? (source as ChatGroupStateRealtime).subscribeToGroupState(
            groupId,
            () => unawaited(load()),
          )
        : source is ChatLiveRealtime
        ? source.subscribeToGroup(groupId, () => unawaited(load()))
        : null;
    _scope = scope;
    _groupId = groupId;
    _generation++;
    loadingDetails = false;
    final trusted =
        initialGroup?.id == groupId &&
        initialGroup?.workspaceId == scope.workspaceId &&
        cacheDatabase?.authorized(ChatCacheScope.fromSession(scope, groupId)) ==
            true;
    emit(
      ChatGroupDetailsState(
        loading: !trusted,
        group: trusted ? initialGroup : null,
      ),
    );
    unawaited(load());
  }

  @override
  Future<void> close() async {
    _generation++;
    _scope = null;
    await _subscription?.cancel();
    return super.close();
  }

  Failure detailsFailure(Object error, String fallback) =>
      error is ApiException ? error.toFailure() : Failure(message: fallback);
  bool isCurrent(FeatureSessionScope scope, String groupId, int generation) =>
      !isClosed &&
      _scope == scope &&
      _groupId == groupId &&
      _generation == generation;
}
