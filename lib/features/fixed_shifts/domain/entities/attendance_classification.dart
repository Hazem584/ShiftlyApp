enum AttendanceClassification {
  early,
  onTime,
  late,
  unknown;

  static AttendanceClassification parse(Object? value) => switch (value) {
    'EARLY' => early,
    'ON_TIME' => onTime,
    'LATE' => late,
    _ => unknown,
  };

  bool get isActionable => this != unknown;
}
