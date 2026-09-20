import 'package:shiftly/core/models/manager_profile.dart';

abstract interface class ProfileRepository {
  Future<ManagerProfile> getProfile();
  Future<ManagerProfile> updateProfile(ManagerProfile profile);
}
