part of '../../profile_cubit.dart';

final class ProfileSessionScope extends Equatable {
  const ProfileSessionScope({required this.userId, required this.workspaceId});

  final String userId;
  final String workspaceId;

  @override
  List<Object?> get props => [userId, workspaceId];
}
