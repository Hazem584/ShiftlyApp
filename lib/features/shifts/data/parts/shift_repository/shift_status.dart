part of '../../shift_repository.dart';

enum ShiftStatus {
  scheduled,
  cancelled,
  completed,
  unknown;

  static ShiftStatus parse(Object? value) => switch (value) {
    'SCHEDULED' => scheduled,
    'CANCELLED' => cancelled,
    'COMPLETED' => completed,
    _ => unknown,
  };

  String? get apiValue => switch (this) {
    scheduled => 'SCHEDULED',
    cancelled => 'CANCELLED',
    completed => 'COMPLETED',
    unknown => null,
  };
}
