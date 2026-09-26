import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/features/profile/data/profile_image_picker.dart';
import 'package:shiftly/features/profile/data/profile_repository.dart';

enum ProfileAction { idle, saving, uploadingAvatar, deletingAvatar }

enum ProfileOperationResult {
  success,
  failure,
  cancelled,
  busy,
  imageTooLarge,
  unsupportedImage,
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

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository, {this.onProfileChanged})
    : super(const ProfileLoading());

  static const maxAvatarBytes = 2 * 1024 * 1024;

  final ProfileRepository _repository;
  final void Function(ManagerProfile profile)? onProfileChanged;

  Future<void> load() async {
    try {
      final profile = await _repository.getProfile();
      onProfileChanged?.call(profile);
      emit(ProfileLoaded(profile));
    } catch (_) {
      emit(const ProfileError('Unable to load your profile.'));
    }
  }

  Future<ProfileOperationResult> update({
    required String fullName,
    String? phone,
  }) async => _mutate(
    ProfileAction.saving,
    () => _repository.updateProfile(
      fullName: fullName.trim(),
      phone: phone?.trim(),
    ),
  );

  Future<ProfileOperationResult> uploadAvatar(
    ProfileImageSelection image,
  ) async {
    if (image.bytes.length > maxAvatarBytes) {
      return ProfileOperationResult.imageTooLarge;
    }
    if (image.detectedMimeType == null) {
      return ProfileOperationResult.unsupportedImage;
    }
    return _mutate(
      ProfileAction.uploadingAvatar,
      () => _repository.uploadAvatar(image),
    );
  }

  Future<ProfileOperationResult> deleteAvatar() =>
      _mutate(ProfileAction.deletingAvatar, _repository.deleteAvatar);

  Future<ProfileOperationResult> _mutate(
    ProfileAction action,
    Future<ManagerProfile> Function() operation,
  ) async {
    final current = state;
    if (current is! ProfileLoaded) return ProfileOperationResult.failure;
    if (current.busy) return ProfileOperationResult.busy;

    emit(ProfileLoaded(current.profile, action: action));
    try {
      final profile = await operation();
      onProfileChanged?.call(profile);
      emit(ProfileLoaded(profile));
      return ProfileOperationResult.success;
    } on ApiException catch (error) {
      emit(ProfileLoaded(current.profile, failure: error.toFailure()));
      return error.kind == FailureKind.cancelled
          ? ProfileOperationResult.cancelled
          : ProfileOperationResult.failure;
    } catch (_) {
      emit(
        ProfileLoaded(
          current.profile,
          failure: const Failure(
            message: 'Something went wrong. Please try again.',
          ),
        ),
      );
      return ProfileOperationResult.failure;
    }
  }
}
