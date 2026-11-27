import 'package:equatable/equatable.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

class ChatGroupDetailsState extends Equatable {
  const ChatGroupDetailsState({
    this.loading = true,
    this.group,
    this.mutating = false,
    this.failure,
  });
  final bool loading;
  final ChatGroup? group;
  final bool mutating;
  final Failure? failure;

  @override
  List<Object?> get props => [loading, group, mutating, failure];
}
