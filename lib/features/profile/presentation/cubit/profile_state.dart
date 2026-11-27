import 'package:equatable/equatable.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/models/manager_profile.dart';

enum ProfileAction { idle, saving, uploadingAvatar, deletingAvatar }

enum ProfileOperationResult {
  success,
  failure,
  cancelled,
  busy,
  imageTooLarge,
  unsupportedImage,
  stale,
}

final class ProfileSessionScope extends Equatable {
  const ProfileSessionScope({required this.userId, required this.workspaceId});

  final String userId, workspaceId;

  @override
  List<Object?> get props => [userId, workspaceId];
}

sealed class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

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

final class ProfileError extends ProfileState {
  const ProfileError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
