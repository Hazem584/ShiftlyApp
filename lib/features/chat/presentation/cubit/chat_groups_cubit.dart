import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_gallery.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_group_store.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_media_store.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_message_store.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_outbox_store.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_session_repository.dart';

import 'chat_groups_loader.dart';
import 'chat_groups_mutation.dart';
import 'chat_groups_session_binder.dart';
import 'chat_groups_session_mixin.dart';
import 'chat_groups_state.dart';
import 'chat_groups_unread_loader.dart';

export 'chat_groups_state.dart';

class ChatGroupsCubit extends Cubit<ChatGroupsState>
    with ChatGroupsSessionMixin {
  ChatGroupsCubit(
    this.repository, {
    this.messageCache,
    this.groupCache,
    this.realtime,
    this.mediaCache,
    this.gallery,
    this.outbox,
  }) : super(const ChatGroupsState());

  final ChatGroupStore? groupCache;
  final ChatRealtime? realtime;
  final ChatMessageStore? messageCache;
  final ChatMediaStore? mediaCache;
  final ChatGallery? gallery;
  final ChatOutboxStore? outbox;
  final ChatRepository repository;

  void bindSession(FeatureSessionScope? scope) =>
      bindChatGroupsSession(this, scope);

  @override
  Future<void> load({bool refresh = false}) =>
      loadChatGroupsList(this, refresh: refresh);
  Future<void> refreshUnread() => refreshChatGroupsUnread(this);

  Future<ChatMutationResult> create({
    required String name,
    String? description,
    required List<String> membershipIds,
  }) => mutateChatGroup(
    this,
    (s) => repository.createGroup(
      s.workspaceId,
      name: name,
      description: description,
      memberMembershipIds: membershipIds,
    ),
  );

  Future<ChatMutationResult> update(
    String groupId, {
    required String name,
    String? description,
  }) => mutateChatGroup(
    this,
    (s) => repository.updateGroup(
      s.workspaceId,
      groupId,
      name: name,
      description: description,
    ),
  );

  Future<ChatMutationResult> archive(String groupId) =>
      mutateChatGroup(this, (s) => repository.archiveGroup(s.workspaceId, groupId));

  @override
  Future<void> close() {
    if (repository case final ChatSessionRepository sessionAware) {
      sessionAware.bindChatSession(null);
    }
    unawaited(inboxSubscription?.cancel());
    inboxDebounce?.cancel();
    sessionScope = null;
    resetSessionCounters();
    return super.close();
  }
}
