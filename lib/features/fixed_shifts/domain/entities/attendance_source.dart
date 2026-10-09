enum AttendanceSource {
  legacyShift,
  template,
  unknown;

  static AttendanceSource parse(Object? value) => switch (value) {
    'LEGACY_SHIFT' => legacyShift,
    'TEMPLATE' => template,
    _ => unknown,
  };
}
