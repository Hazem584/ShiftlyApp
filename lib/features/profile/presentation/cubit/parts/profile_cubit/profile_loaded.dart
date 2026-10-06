part of '../../profile_cubit.dart';

final class ProfileLoaded extends ProfileState {
  const ProfileLoaded(
    this.profile, {
    this.action = ProfileAction.idle,
    this.failure,
  });

  final ManagerProfile profile;
  final ProfileAction action;
  final Failure? failure;

  bool get saving => action == ProfileAction.saving;
  bool get busy => action != ProfileAction.idle;

  @override
  List<Object?> get props => [profile, action, failure];
}
