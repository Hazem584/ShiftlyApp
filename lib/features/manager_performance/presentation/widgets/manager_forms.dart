import 'manager_form_field.dart';

abstract final class ManagerForms {
  static const adjustmentReasons = [
    'TECHNICAL_CORRECTION',
    'ATTENDANCE_CORRECTION',
    'POLICY_EXCEPTION',
    'DISPUTE_RESOLUTION',
    'OTHER',
  ];
  static const effortReasons = [
    'COVERED_EMPLOYEE',
    'ADDITIONAL_SHIFT',
    'APPROVED_OVERTIME',
    'EMERGENCY_SUPPORT',
    'HIGH_WORKLOAD_SUPPORT',
    'OTHER',
  ];
  static const explanation = ManagerFormField(
    'explanation',
    'Explanation',
    minimum: 5,
    maximum: 1000,
  );
  static List<ManagerFormField> adjustment({bool reverse = false}) => [
    if (!reverse) ...[
      const ManagerFormField(
        'pointType',
        'Point type',
        choices: ['GREEN', 'BLACK', 'RED', 'ORANGE', 'BLUE'],
      ),
      const ManagerFormField(
        'amount',
        'Quantity (negative to subtract)',
        minimum: -100,
        maximum: 100,
        initial: 1,
        help: 'Zero is not permitted. The server checks available balances.',
      ),
    ],
    const ManagerFormField('reason', 'Reason', choices: adjustmentReasons),
    explanation,
  ];
  static List<ManagerFormField> effort({bool reverse = false}) => [
    if (!reverse)
      const ManagerFormField(
        'bluePoints',
        'BLUE points',
        minimum: 1,
        maximum: 100,
        initial: 1,
        help: 'Linked GREEN credits are calculated by the server using the effective policy.',
      ),
    reverse
        ? const ManagerFormField(
            'reason',
            'Reversal reason',
            minimum: 3,
            maximum: 100,
          )
        : const ManagerFormField('reason', 'Reason', choices: effortReasons),
    explanation,
  ];
  static const review = [
    ManagerFormField('decision', 'Decision', choices: ['APPROVED', 'REJECTED']),
    ManagerFormField(
      'response',
      'Response to employee',
      minimum: 5,
      maximum: 1000,
    ),
  ];
  static const policy = [
    ManagerFormField(
      'effectiveFrom',
      'Effective date (YYYY-MM-DD)',
      date: true,
      help: 'A new version applies from this workspace-local date. Historical evaluations retain their policy version.',
    ),
    ManagerFormField(
      'greenPointsForCompletedAttendance',
      'Attendance · GREEN for completed attendance',
      minimum: 0,
      maximum: 100,
      initial: 1,
    ),
    ManagerFormField(
      'blackPointsForLateAttendance',
      'Attendance · BLACK for late attendance',
      minimum: 0,
      maximum: 100,
      initial: 1,
    ),
    ManagerFormField(
      'redPointsForAbsence',
      'Attendance · RED for absence',
      minimum: 0,
      maximum: 100,
      initial: 1,
    ),
    ManagerFormField(
      'orangePointsForIncompleteAttendance',
      'Attendance · ORANGE for incomplete attendance',
      minimum: 0,
      maximum: 100,
      initial: 1,
    ),
    ManagerFormField(
      'bluePointsForExtraEffort',
      'Extra effort · default BLUE',
      minimum: 0,
      maximum: 100,
      initial: 1,
    ),
    ManagerFormField(
      'blueGreenEquivalent',
      'Extra effort · GREEN credits per BLUE',
      minimum: 0,
      maximum: 100,
      initial: 2,
    ),
    ManagerFormField(
      'greenCostPerRedCompensation',
      'Compensation · GREEN cost per RED',
      minimum: 1,
      maximum: 1000,
      initial: 5,
    ),
    ManagerFormField(
      'monthlyRedCompensationLimit',
      'Compensation · monthly RED limit',
      minimum: 0,
      maximum: 100,
      initial: 2,
    ),
    ManagerFormField(
      'blackPointsWarningThreshold',
      'Warnings · BLACK threshold per cycle',
      minimum: 1,
      maximum: 1000,
      initial: 3,
    ),
    ManagerFormField(
      'streakRewardEnabled',
      'Streak · enable reward',
      boolean: true,
      initial: true,
    ),
    ManagerFormField(
      'streakRequiredDays',
      'Streak · required days',
      minimum: 1,
      maximum: 365,
      initial: 5,
    ),
    ManagerFormField(
      'streakGreenReward',
      'Streak · GREEN reward',
      minimum: 0,
      maximum: 100,
      initial: 1,
    ),
    ManagerFormField(
      'disputeWindowHours',
      'Disputes · submission window (hours)',
      minimum: 1,
      maximum: 2160,
      initial: 48,
    ),
    ManagerFormField(
      'earlyDepartureToleranceMinutes',
      'Deadlines · early departure tolerance (minutes)',
      minimum: 0,
      maximum: 1440,
      initial: 15,
    ),
    ManagerFormField(
      'incompleteAttendanceResolutionMinutes',
      'Deadlines · incomplete attendance resolution (minutes)',
      minimum: 1,
      maximum: 10080,
      initial: 720,
    ),
    ManagerFormField(
      'isEnabled',
      'Enable Points policy',
      boolean: true,
      initial: true,
    ),
  ];
}
