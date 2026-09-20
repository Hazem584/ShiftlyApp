import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/features/profile/data/profile_repository.dart';

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
  Future<ManagerProfile> updateProfile(ManagerProfile profile) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    _profile = profile;
    return _profile;
  }
}
