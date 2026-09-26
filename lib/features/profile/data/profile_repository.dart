import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/features/profile/data/profile_image_picker.dart';

abstract interface class ProfileRepository {
  Future<ManagerProfile> getProfile();
  Future<ManagerProfile> updateProfile({
    required String fullName,
    required String? phone,
  });
  Future<ManagerProfile> uploadAvatar(ProfileImageSelection image);
  Future<ManagerProfile> deleteAvatar();
}
