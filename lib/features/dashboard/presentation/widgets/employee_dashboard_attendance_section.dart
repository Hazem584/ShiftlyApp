import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_active_attendance_screen.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_attendance_gate.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_attendance_hero.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';

class EmployeeDashboardAttendanceSection extends StatelessWidget {
  const EmployeeDashboardAttendanceSection({
    required this.timezone,
    this.now,
    super.key,
  });
  final String timezone;
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<FlexibleAttendanceCubit, FlexibleAttendanceState>(
        builder: (context, att) {
          final active = att.current;
          final showHero =
              active != null &&
              active.isOpen &&
              active.isActionable &&
              att.recovery == null &&
              !att.recoveryBlocked;
          if (!showHero) {
            return EmployeeAttendanceGate(state: att, timezone: timezone);
          }
          return EmployeeAttendanceHero(
            attendance: active,
            now: now,
            timezone: timezone,
            overview: true,
            onOpen: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) =>
                    EmployeeActiveAttendanceScreen(timezone: timezone),
              ),
            ),
          );
        },
      );
}
