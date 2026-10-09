enum AttendanceReviewStatus {
  pending,
  approved,
  rejected,
  unknown;

  static AttendanceReviewStatus parse(Object? value) => switch (value) {
    'PENDING' => pending,
    'APPROVED' => approved,
    'REJECTED' => rejected,
    _ => unknown,
  };
}
