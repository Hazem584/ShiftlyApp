import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/shifts/data/shift_repository.dart';

part 'parts/shift_card/shift_card.dart';
part 'parts/shift_card/shift_status_badge.dart';

String attendanceReviewLabel(AttendanceReviewStatus status) => switch (status) {
  AttendanceReviewStatus.pending => 'Pending review',
  AttendanceReviewStatus.approved => 'Approved',
  AttendanceReviewStatus.rejected => 'Rejected',
  AttendanceReviewStatus.unknown => 'Unavailable',
};
