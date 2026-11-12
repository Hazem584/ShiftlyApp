import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/employee_design.dart';
import 'package:shiftly/features/breaks/application/shift_break_controller.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/flexible_attendance.dart';

import 'employee_formatters.dart';

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
    final h = (net ~/ 3600).toString().padLeft(2, '0'),
        m = (net % 3600 ~/ 60).toString().padLeft(2, '0'),
        s = (net % 60).toString().padLeft(2, '0');
    final dark = Theme.of(context).brightness == Brightness.dark;
    String time(DateTime? d) => employeeTime(context, d, widget.timezone);
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF163D35) : const Color(0xFFDCF5EA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 7,
                  color: dark
                      ? const Color(0xFF88E3BF)
                      : const Color(0xFF116B57),
                ),
                const SizedBox(width: 6),
                Text(
                  context
                      .tr(
                        breaks?.running == true
                            ? '● On break'
                            : a.isOpen
                            ? '● On shift'
                            : 'Shift complete',
                      )
                      .replaceAll('●', '')
                      .trim(),
                  style: TextStyle(
                    color: dark
                        ? const Color(0xFF88E3BF)
                        : const Color(0xFF116B57),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (widget.overview) ...[
            Text(
              a.templateName ?? context.tr('Fixed shift'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${time(a.scheduledStartAt)} – ${time(a.scheduledEndAt)} · ${widget.timezone}',
              style: const TextStyle(
                color: EmployeeDesign.heroText,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 20),
          ],
          Directionality(
            textDirection: TextDirection.ltr,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$h:$m:$s',
                key: const Key('employee-worked-clock'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 46,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('Checked in at {time} · {status}', {
              'time': time(a.clockInAt),
              'status': context.tr(a.minutesLate > 0 ? 'Late' : 'On time'),
            }),
            style: const TextStyle(
              color: EmployeeDesign.heroText,
              fontSize: 14,
            ),
          ),
          if (!widget.overview) ...[
            const SizedBox(height: 14),
            Text(
              context.tr('Scheduled {start}–{end}', {
                'start': time(a.scheduledStartAt),
                'end': time(a.scheduledEndAt),
              }),
              style: const TextStyle(color: EmployeeDesign.heroText),
            ),
          ],
          if (widget.onOpen != null) ...[
            const SizedBox(height: 20),
            const Divider(color: Color(0xFF414966)),
            TextButton(
              key: const Key('view-active-attendance'),
              onPressed: widget.onOpen,
              style: TextButton.styleFrom(
                foregroundColor: EmployeeDesign.mint,
                padding: EdgeInsets.zero,
                alignment: AlignmentDirectional.centerStart,
              ),
              child: Row(
                children: [
                  Expanded(child: Text(context.tr('View attendance'))),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
