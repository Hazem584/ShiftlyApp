part of '../../chat_groups_cubit.dart';

class ChatGroupsState extends Equatable {
  const ChatGroupsState({
    this.loading = true,
    this.groups = const [],
    this.unreadCount = 0,
    this.refreshing = false,
    this.mutating = false,
    this.failure,
  });

  final bool loading;
  final List<ChatGroup> groups;
  final int unreadCount;
  final bool refreshing;
  final bool mutating;
  final Failure? failure;

  ChatGroupsState copyWith({
    bool? loading,
    List<ChatGroup>? groups,
    int? unreadCount,
    bool? refreshing,
    bool? mutating,
    Failure? failure,
    bool clearFailure = false,
  }) => ChatGroupsState(
    loading: loading ?? this.loading,
    groups: groups ?? this.groups,
    unreadCount: unreadCount ?? this.unreadCount,
    refreshing: refreshing ?? this.refreshing,
    mutating: mutating ?? this.mutating,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    loading,
    groups,
    unreadCount,
    refreshing,
    mutating,
    failure,
  ];
}
