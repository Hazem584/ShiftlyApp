import 'package:shiftly/features/auth/data/models/current_user.dart';

abstract interface class AuthenticationRepository {
  Future<CurrentUser> loadCurrentUser();

  Future<void> bootstrapProfile({String? fullName, String? phone});
}
