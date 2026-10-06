import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/routing/app_routes.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/dashboard/data/dashboard_repository.dart';

part 'parts/dashboard_activity_section/dashboard_activity_section.dart';
part 'parts/dashboard_activity_section/dashboard_approvals_card.dart';

part 'parts/dashboard_activity_section/private_shift_tile.dart';

String _attendanceLabel(DashboardAttendance? attendance) =>
    switch (attendance?.status) {
      DashboardAttendanceStatus.clockedIn => 'Clocked in',
      DashboardAttendanceStatus.completed => 'Completed',
      DashboardAttendanceStatus.unknown => 'Recorded',
      null => 'Scheduled',
    };
