import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/attendance/presentation/screens/employee_attendance_screen.dart';
import 'package:shiftly/features/dashboard/presentation/screens/employee_dashboard_screen.dart';
import 'package:shiftly/features/shifts/presentation/screens/employee_shifts_screen.dart';
import 'package:shiftly/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:shiftly/features/auth/presentation/widgets/workspace_switcher.dart';
import 'package:shiftly/features/chat/presentation/screens/chat_groups_screen.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';

part 'parts/employee_shell_screen/private_employee_shell_screen_state.dart';

class EmployeeShellScreen extends StatefulWidget {
  const EmployeeShellScreen({this.initialTab = 0, super.key});

  final int initialTab;

  @override
  State<EmployeeShellScreen> createState() => _EmployeeShellScreenState();
}
