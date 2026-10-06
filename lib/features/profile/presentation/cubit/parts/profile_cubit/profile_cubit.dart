part of '../../profile_cubit.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository, {this.onProfileChanged})
    : super(const ProfileLoading());

  static const maxAvatarBytes = 2 * 1024 * 1024;

  final ProfileRepository _repository;
  final void Function(ManagerProfile profile)? onProfileChanged;
  ProfileSessionScope? _sessionScope;
  var _generation = 0;
  var _usesSessionBinding = false;

  void bindSession(ProfileSessionScope? scope) {
    _usesSessionBinding = true;
    if (_sessionScope == scope) return;

    _sessionScope = scope;
    _generation += 1;
    emit(const ProfileLoading());
    if (scope != null) {
      unawaited(_load(scope: scope, generation: _generation));
    }
  }

  Future<void> load() async {
    if (_usesSessionBinding && _sessionScope == null) return;
    emit(const ProfileLoading());
    await _load(scope: _sessionScope, generation: _generation);
  }

  Future<void> _load({
    required ProfileSessionScope? scope,
    required int generation,
  }) async {
    try {
      final profile = await _repository.getProfile();
      if (!_isCurrent(scope, generation)) return;
      onProfileChanged?.call(profile);
      emit(ProfileLoaded(profile));
    } catch (_) {
      if (!_isCurrent(scope, generation)) return;
      emit(const ProfileError('Unable to load your profile.'));
    }
  }

  Future<ProfileOperationResult> update({
    required String fullName,
    required String? phone,
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

    final scope = _sessionScope;
    final generation = _generation;

    emit(ProfileLoaded(current.profile, action: action));
    try {
      final profile = await operation();
      if (!_isCurrent(scope, generation)) return ProfileOperationResult.stale;
      onProfileChanged?.call(profile);
      emit(ProfileLoaded(profile));
      return ProfileOperationResult.success;
    } on ApiException catch (error) {
      if (!_isCurrent(scope, generation)) return ProfileOperationResult.stale;
      emit(ProfileLoaded(current.profile, failure: error.toFailure()));
      return error.kind == FailureKind.cancelled
          ? ProfileOperationResult.cancelled
          : ProfileOperationResult.failure;
    } catch (_) {
      if (!_isCurrent(scope, generation)) return ProfileOperationResult.stale;
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

  bool _isCurrent(ProfileSessionScope? scope, int generation) =>
      !isClosed && generation == _generation && scope == _sessionScope;
}
