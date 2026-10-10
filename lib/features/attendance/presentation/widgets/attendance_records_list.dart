import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_record_card.dart';

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
      Text(context.tr(title), style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.s),
      for (final record in records) ...[
        AttendanceRecordCard(
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
