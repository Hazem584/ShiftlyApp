part of '../../fixed_shift_repository.dart';

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
