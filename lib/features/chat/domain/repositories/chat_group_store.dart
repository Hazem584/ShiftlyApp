import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_group.dart';

typedef ChatGroupSnapshot = ({List<ChatGroup> groups, int unreadCount});

abstract interface class ChatGroupStore {
  Future<ChatGroupSnapshot?> read(FeatureSessionScope scope);
  Future<void> write(FeatureSessionScope scope, ChatGroupSnapshot value);
}
