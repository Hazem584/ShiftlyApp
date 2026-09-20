import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/features/profile/data/profile_repository.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

final class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.profile, {this.saving = false});
  final ManagerProfile profile;
  final bool saving;
  @override
  List<Object?> get props => [profile, saving];
}

final class ProfileError extends ProfileState {
  const ProfileError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository) : super(const ProfileLoading());
  final ProfileRepository _repository;

  Future<void> load() async {
    try {
      emit(ProfileLoaded(await _repository.getProfile()));
    } catch (_) {
      emit(const ProfileError('Unable to load your profile.'));
    }
  }

  Future<bool> update(ManagerProfile profile) async {
    emit(ProfileLoaded(profile, saving: true));
    try {
      emit(ProfileLoaded(await _repository.updateProfile(profile)));
      return true;
    } catch (_) {
      emit(ProfileLoaded(profile));
      return false;
    }
  }
}
