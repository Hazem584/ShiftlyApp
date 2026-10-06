import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/attendance/data/attendance_repository.dart';
import 'package:shiftly/features/fixed_shifts/data/fixed_shift_repository.dart';
import 'package:shiftly/features/shifts/data/shift_repository.dart';

part 'parts/attendance_records_list/private_attendance_record_card.dart';

class AttendanceRecordsList extends StatelessWidget {
  const AttendanceRecordsList({
    required this.records,
    required this.timezone,
    this.title = 'Recent Attendance',
    this.onTap,
    this.trailing,
    super.key,
  });

  final List<AttendanceRecordApi> records;
  final String timezone;
  final String title;
  final ValueChanged<AttendanceRecordApi>? onTap;
  final Widget Function(AttendanceRecordApi record)? trailing;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.s),
      for (final record in records) ...[
        _AttendanceRecordCard(
          record: record,
          timezone: timezone,
          onTap: onTap == null ? null : () => onTap!(record),
          trailing: trailing?.call(record),
        ),
        const SizedBox(height: 10),
      ],
    ],
  );
}
