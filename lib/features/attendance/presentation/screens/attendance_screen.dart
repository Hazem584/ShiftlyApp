import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/screen_header.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/attendance_calendar_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_calendar_state.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_metrics_section.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_tab_selector.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_requests_panel.dart';
import 'package:shiftly/features/attendance/presentation/widgets/manager_attendance_panel.dart';

part 'parts/attendance_screen/private_attendance_screen_state.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({
    this.initialTab = 0,
    this.timezone = 'Etc/UTC',
    super.key,
  });

  final int initialTab;
  final String timezone;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}
