import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/theme/employee_design.dart';
import 'package:shiftly/core/theme/manager_design.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_record_card_details.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_record_tile.dart';

class AttendanceRecordCard extends StatelessWidget {
  const AttendanceRecordCard({
    super.key,
    required this.record,
    required this.timezone,
    this.onTap,
    this.trailing,
  });
  final AttendanceRecordApi record;
  final String timezone;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    if (EmployeeDesign.applies(context) && !ManagerDesign.applies(context)) {
      return EmployeeRecordTile(record: record, timezone: timezone);
    }
    final savedTimezone = record.workspaceTimezone ?? timezone;
    final date = WorkspaceTime.inWorkspace(
      record.shift?.startsAt ?? record.scheduledStartAt ?? record.clockInAt,
      savedTimezone,
    );
    final (label, color, background) = attendanceReviewStatusStyle(
      context,
      record.reviewStatus,
    );
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                Text(
                  date.day.toString().padLeft(2, '0'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  context.tr(attendanceMonthAbbrev(date.month)),
                  style: TextStyle(
                    color: AppPalette.of(context).textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: buildAttendanceRecordDetailsColumn(
              context,
              record,
              savedTimezone,
            ),
          ),
          const SizedBox(width: 8),
          trailing ??
              DecoratedBox(
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    context.tr(label),
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
