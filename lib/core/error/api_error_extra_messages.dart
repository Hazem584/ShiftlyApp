String? apiErrorExtraMessage(String? code) => switch (code) {
  'EXTRA_AUTHORIZATION_UNAVAILABLE' =>
    'This extra authorization is unavailable. Refresh and ask your manager.',
  'EXTRA_OCCURRENCE_CONFLICT' =>
    'This extra occurrence is already reserved or attended. Review history.',
  'EXTRA_IS_BASELINE' =>
    'This occurrence is the assigned baseline. An extra must be a separate occurrence.',
  'EXTRA_ALREADY_CONSUMED' =>
    'This extra has been consumed and cannot be revoked.',
  'EXTRA_IDEMPOTENCY_CONFLICT' =>
    'The saved extra request conflicts with an earlier operation. Keep its evidence and contact support.',
  'EXTRA_SCHEDULE_OVERLAP' =>
    'This extra overlaps a baseline or another reserved extra. Choose a different occurrence.',
  'EXTRA_DATE_IN_PAST' =>
    'The check-in window has expired. Record actual attendance for already-worked extras.',
  'EXTRA_DATE_INVALID' => 'Choose a valid operational date.',
  'EXTRA_ACTUAL_RANGE_INVALID' =>
    'Actual clock-out must follow clock-in and both times must be in the past.',
  'EXTRA_ACTUAL_OCCURRENCE_INVALID' =>
    'Actual clock-in must fall within the occurrence check-in window.',
  'EXTRA_MEMBERSHIP_EVIDENCE_UNAVAILABLE' =>
    'The employee membership was not established at that clock-in time.',
  'EXTRA_AUTHORIZATION_NOT_FOUND' =>
    'This extra authorization is unavailable. Refresh history.',
  'SCHEDULE_DST_POLICY_REVIEW_REQUIRED' =>
    'This historical schedule needs daylight saving policy review. Contact your manager.',
  'SCHEDULE_INTERVAL_INVALID' =>
    'This schedule produces an invalid time interval. Review its daylight saving boundaries.',
  'SCHEDULE_POLICY_UNSUPPORTED' =>
    'This schedule policy is unsupported. Update the app or contact support.',
  'LEGACY_CLOCK_IN_DISABLED' =>
    'Legacy clock-in is disabled. Use your assigned fixed shift or an authorized extra.',
  _ => null,
};
