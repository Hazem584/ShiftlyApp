import 'package:shiftly/core/error/api_exception.dart';

/// Only explicit business/DTO rejections prove that no new write occurred.
bool confirmedMutationRejection(Object error) =>
    error is ApiException &&
    (error.statusCode == 400 ||
        const {
          'ATTENDANCE_OCCURRENCE_ALREADY_USED',
          'ATTENDANCE_ALREADY_OPEN',
          'SHIFT_TEMPLATE_NOT_ASSIGNED',
          'SHIFT_ASSIGNMENT_REQUIRED',
          'SHIFT_TEMPLATE_NOT_ELIGIBLE',
          'SHIFT_TEMPLATE_ARCHIVED',
          'SHIFT_TEMPLATE_UNAVAILABLE',
          'EXTRA_AUTHORIZATION_UNAVAILABLE',
          'EXTRA_AUTHORIZATION_NOT_FOUND',
          'EXTRA_IDEMPOTENCY_CONFLICT',
          'EXTRA_OCCURRENCE_CONFLICT',
          'EXTRA_IS_BASELINE',
          'EXTRA_ALREADY_CONSUMED',
          'EXTRA_SCHEDULE_OVERLAP',
          'EXTRA_DATE_IN_PAST',
          'ATTENDANCE_OVERLAP',
          'OUTSIDE_WORK_LOCATION',
          'LOCATION_REQUIRED',
          'LOCATION_SERVICES_DISABLED',
          'LOCATION_PERMISSION_DENIED',
          'LOCATION_ACCURACY_TOO_LOW',
          'MOCK_LOCATION_DETECTED',
          'SELFIE_REQUIRED',
          'SELFIE_CAMERA_UNAVAILABLE',
          'SELFIE_INVALID',
          'SELFIE_TOO_LARGE',
          'SCHEDULE_DST_POLICY_REVIEW_REQUIRED',
          'SCHEDULE_INTERVAL_INVALID',
          'SCHEDULE_POLICY_UNSUPPORTED',
        }.contains(error.code));
