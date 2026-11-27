import 'dart:async';

import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

import 'chat_conversation_host.dart';
import 'chat_conversation_older_loader.dart';
import 'chat_conversation_page_loader.dart';

class ChatConversationPager {
  ChatConversationPager(
    this.host, {
    required this.loadGroup,
    required this.restoreOutbox,
    required this.drainOutbox,
    required this.clearInboxHint,
  });

  final ChatConversationHost host;
  final Future<ChatGroup> Function()? loadGroup;
  final Future<void> Function() restoreOutbox, drainOutbox;
  final void Function() clearInboxHint;

  var request = 0;
  Future<void> pagePersistence = Future<void>.value();
  bool loadingPage = false, refreshQueued = false;
  bool cacheRestored = false, latestLoaded = false;
  Set<String> gapBoundaryIds = {};
  String? historyCursor;

  void reset() {
    request++;
    cacheRestored = false;
    latestLoaded = false;
    gapBoundaryIds = {};
    historyCursor = null;
    loadingPage = false;
    refreshQueued = false;
  }

  bool current(FeatureSessionScope s, String g, int gen, int req) =>
      host.scopeCurrent(s, g, gen) && request == req;

  void finishPageLoad(FeatureSessionScope s, String g, int gen) {
    if (host.scopeCurrent(s, g, gen)) {
      loadingPage = false;
      if (refreshQueued) {
        refreshQueued = false;
        unawaited(load(refresh: true));
      }
    }
  }

  Future<void> load({bool refresh = false}) =>
      loadChatConversationPage(this, refresh: refresh);
  Future<void> loadOlder() => loadOlderChatMessages(this);
}
