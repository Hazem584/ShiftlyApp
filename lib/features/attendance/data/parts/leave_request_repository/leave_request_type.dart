part of '../../leave_request_repository.dart';

enum LeaveRequestType {
  annualLeave,
  sickLeave,
  emergencyLeave,
  earlyLeave,
  other,
  unknown;

  static LeaveRequestType parse(Object? value) => switch (value) {
    'ANNUAL_LEAVE' => annualLeave,
    'SICK_LEAVE' => sickLeave,
    'EMERGENCY_LEAVE' => emergencyLeave,
    'EARLY_LEAVE' => earlyLeave,
    'OTHER' => other,
    _ => unknown,
  };

  String? get apiValue => switch (this) {
    annualLeave => 'ANNUAL_LEAVE',
    sickLeave => 'SICK_LEAVE',
    emergencyLeave => 'EMERGENCY_LEAVE',
    earlyLeave => 'EARLY_LEAVE',
    other => 'OTHER',
    unknown => null,
  };
}
