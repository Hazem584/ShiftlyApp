enum MembershipStatus {
  invited,
  active,
  suspended,
  left,
  unknown;

  static MembershipStatus parse(Object? value) => switch (value) {
    'INVITED' => invited,
    'ACTIVE' => active,
    'SUSPENDED' => suspended,
    'LEFT' => left,
    _ => unknown,
  };
}
