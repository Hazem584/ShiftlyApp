part of '../../current_user.dart';

enum MembershipStatus {
  invited,
  active,
  suspended,
  unknown;

  static MembershipStatus parse(Object? value) => switch (value) {
    'INVITED' => invited,
    'ACTIVE' => active,
    'SUSPENDED' => suspended,
    _ => unknown,
  };
}
