import 'package:shiftly/features/fixed_shifts/domain/entities/attendance_source.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/flexible_attendance.dart';

import 'attendance_status_summary.dart';

AttendanceStatusSummary openAttendanceSummary(
  FlexibleAttendance current, {
  required bool hasFailure,
  required String actionLocation,
}) {
  return AttendanceStatusSummary(
    title: current.isActionable
        ? 'You are clocked in'
        : 'An earlier attendance is still open',
    message: current.isActionable
        ? hasFailure
              ? 'Your last confirmed status is clocked in. Refresh to confirm the latest status before finishing.'
              : 'When you finish working, use Clock out {location}.'
        : current.source == AttendanceSource.legacyShift
        ? 'Open Earlier shifts & clock-out to finish this attendance.'
        : 'Refresh your attendance before taking another action.',
    tone: current.isActionable
        ? AttendanceStatusTone.active
        : AttendanceStatusTone.attention,
    arguments: {'location': actionLocation},
  );
}
