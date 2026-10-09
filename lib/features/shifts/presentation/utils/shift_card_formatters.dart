import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

String attendanceReviewLabel(AttendanceReviewStatus status) => switch (status) {
  AttendanceReviewStatus.pending => 'Pending review',
  AttendanceReviewStatus.approved => 'Approved',
  AttendanceReviewStatus.rejected => 'Rejected',
  AttendanceReviewStatus.unknown => 'Unavailable',
};
