import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/employee_design.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/flexible_attendance.dart';

import 'employee_formatters.dart';

class EmployeeAttendanceHeroBody extends StatelessWidget {
  const EmployeeAttendanceHeroBody({
    required this.attendance,
    required this.timezone,
    required this.clockText,
    required this.overview,
    this.onOpen,
    super.key,
  });

  final FlexibleAttendance attendance;
  final String timezone;
  final String clockText;
  final bool overview;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    String time(DateTime? d) => employeeTime(context, d, timezone);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (overview) ...[
          Text(
            attendance.templateName ?? context.tr('Fixed shift'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${time(attendance.scheduledStartAt)} – ${time(attendance.scheduledEndAt)} · $timezone',
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
              clockText,
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
            'time': time(attendance.clockInAt),
            'status': context.tr(
              attendance.minutesLate > 0 ? 'Late' : 'On time',
            ),
          }),
          style: const TextStyle(color: EmployeeDesign.heroText, fontSize: 14),
        ),
        if (!overview) ...[
          const SizedBox(height: 14),
          Text(
            context.tr('Scheduled {start}–{end}', {
              'start': time(attendance.scheduledStartAt),
              'end': time(attendance.scheduledEndAt),
            }),
            style: const TextStyle(color: EmployeeDesign.heroText),
          ),
        ],
        if (onOpen != null) ...[
          const SizedBox(height: 20),
          const Divider(color: Color(0xFF414966)),
          TextButton(
            key: const Key('view-active-attendance'),
            onPressed: onOpen,
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
    );
  }
}
