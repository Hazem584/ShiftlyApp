import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/theme/employee_design.dart';
import 'package:shiftly/features/breaks/application/shift_break_controller.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/flexible_attendance.dart';

import 'employee_attendance_hero_badge.dart';
import 'employee_attendance_hero_body.dart';

class EmployeeAttendanceHero extends StatefulWidget {
  const EmployeeAttendanceHero({
    required this.attendance,
    required this.timezone,
    this.onOpen,
    this.overview = false,
    this.now,
    super.key,
  });
  final FlexibleAttendance attendance;
  final String timezone;
  final VoidCallback? onOpen;
  final bool overview;
  final DateTime Function()? now;
  @override
  State<EmployeeAttendanceHero> createState() => _EmployeeAttendanceHeroState();
}

class _EmployeeAttendanceHeroState extends State<EmployeeAttendanceHero> {
  Timer? _ticker;
  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && TickerMode.valuesOf(context).enabled) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.attendance;
    final breaks = context.read<ShiftBreakController?>();
    final elapsed = (a.clockOutAt ?? widget.now?.call() ?? DateTime.now())
        .difference(a.clockInAt)
        .inSeconds;
    final net =
        (elapsed - (breaks?.takenSeconds ?? a.breakState?.consumedSeconds ?? 0))
            .clamp(0, 9999999);
    final h = (net ~/ 3600).toString().padLeft(2, '0');
    final m = (net % 3600 ~/ 60).toString().padLeft(2, '0');
    final s = (net % 60).toString().padLeft(2, '0');
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: const Key('employee-attendance-hero'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dark ? EmployeeDesign.heroDark : EmployeeDesign.hero,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmployeeAttendanceHeroBadge(
            onBreak: breaks?.running == true,
            isOpen: a.isOpen,
            dark: dark,
          ),
          const SizedBox(height: 20),
          EmployeeAttendanceHeroBody(
            attendance: a,
            timezone: widget.timezone,
            clockText: '$h:$m:$s',
            overview: widget.overview,
            onOpen: widget.onOpen,
          ),
        ],
      ),
    );
  }
}
