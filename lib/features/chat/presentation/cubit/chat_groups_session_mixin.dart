import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';

import 'chat_groups_state.dart';

mixin ChatGroupsSessionMixin on Cubit<ChatGroupsState> {
  ChatRealtimeSubscription? inboxSubscription;
  Timer? inboxDebounce;
  bool groupsRestored = false;
  FeatureSessionScope? sessionScope;
  var generation = 0, request = 0, unreadRequest = 0;
  var unreadIssuedSequence = 0, unreadAppliedSequence = 0;
  bool loadingGroups = false, refreshQueued = false;
  bool unreadRefreshing = false, unreadRefreshQueued = false;

  FeatureSessionScope? get scope => sessionScope;
  void emitState(ChatGroupsState value) => emit(value);
  Future<void> load({bool refresh = false});

  bool current(FeatureSessionScope s, int gen, int req) =>
      scopeCurrent(s, gen) && request == req;
  bool scopeCurrent(FeatureSessionScope s, int gen) =>
      !isClosed && sessionScope == s && generation == gen;
  bool unreadCurrent(FeatureSessionScope s, int gen, int req) =>
      scopeCurrent(s, gen) && unreadRequest == req;

  bool acceptUnreadResult(FeatureSessionScope s, int gen, int sequence) {
    if (!scopeCurrent(s, gen) || sequence < unreadAppliedSequence) return false;
    unreadAppliedSequence = sequence;
    return true;
  }

  void finishGroupsLoad(FeatureSessionScope s, int gen) {
    if (scopeCurrent(s, gen)) {
      loadingGroups = false;
      if (refreshQueued) {
        refreshQueued = false;
        unawaited(load(refresh: true));
      }
    }
  }

  void resetSessionCounters() {
    generation++;
    request++;
    unreadRequest++;
    loadingGroups = false;
    refreshQueued = false;
    unreadRefreshing = false;
    unreadRefreshQueued = false;
    unreadIssuedSequence = 0;
    unreadAppliedSequence = 0;
  }
}
