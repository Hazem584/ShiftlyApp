import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/features/profile/data/profile_image_picker.dart';
import 'package:shiftly/features/profile/domain/repositories/profile_repository.dart';

class MockProfileRepository implements ProfileRepository {
  MockProfileRepository({this.delay = Duration.zero});
  final Duration delay;
  ManagerProfile _profile = const ManagerProfile(
    fullName: 'Mona Ibrahim',
    role: 'Operations Manager',
    email: 'mona@shiftlab.com',
    phone: '+20 100 234 5678',
    workplace: 'Shift Lab',
  );

  @override
  Future<ManagerProfile> getProfile() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return _profile;
  }

  @override
  Future<ManagerProfile> updateProfile({
    required String fullName,
    required String? phone,
  }) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    _profile = _profile.copyWith(
      fullName: fullName,
      phone: phone,
      clearPhone: phone == null,
    );
    return _profile;
  }

  @override
  Future<ManagerProfile> uploadAvatar(ProfileImageSelection image) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    _profile = _profile.copyWith(photoBytes: image.bytes);
    return _profile;
  }

  @override
  Future<ManagerProfile> deleteAvatar() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    _profile = ManagerProfile(
      id: _profile.id,
      fullName: _profile.fullName,
      role: _profile.role,
      email: _profile.email,
      phone: _profile.phone,
      workplace: _profile.workplace,
      createdAt: _profile.createdAt,
      updatedAt: _profile.updatedAt,
    );
    return _profile;
  }
}
