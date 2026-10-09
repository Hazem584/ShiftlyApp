import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_repository.dart';

class OnboardingTestRepository implements AuthenticationRepository {
  OnboardingTestRepository(this.user, {this.failure});
  final CurrentUser user;
  final ApiException? failure;
  @override
  Future<void> bootstrapProfile({String? fullName, String? phone}) async {}
  @override
  Future<CurrentUser> loadCurrentUser() async {
    if (failure case final error?) {
      throw error;
    }
    return user;
  }
}
