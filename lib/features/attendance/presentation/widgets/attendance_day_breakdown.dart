import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_record_api.dart';
import 'package:shiftly/features/shifts/domain/entities/attendance_review_status.dart';

class AttendanceDayBreakdown extends StatelessWidget {
  const AttendanceDayBreakdown({required this.record, super.key});
  final AttendanceRecordApi record;
  @override
  Widget build(BuildContext context) {
    final c = record.calculation;
    if (c == null) return const SizedBox.shrink();
    String duration(Object? value) => value is num
        ? context.tr('{hours}h {minutes}m', {
            'hours': '${value.toInt() ~/ 60}',
            'minutes': '${value.toInt() % 60}',
          })
        : context.tr('Not available');
    final approved =
        record.reviewStatus == AttendanceReviewStatus.approved &&
        record.clockOutAt != null;
    final rows = <String, Object?>{
      'Elapsed attendance': c['elapsedMinutes'],
      'Planned break': c['plannedBreakMinutes'],
      'Break deducted for late arrival': c['lateBreakDeductionMinutes'],
      'Available break': c['allowedBreakMinutes'],
      'Actual break taken': c['breakTakenMinutes'],
      'Recorded work after breaks': c['netWorkedMinutes'],
      'Expected work': c['expectedWorkMinutes'],
      'Post-shift overtime after making up lateness':
          c['postShiftOvertimeMinutes'],
      'Unused break overtime': c['unusedBreakOvertimeMinutes'],
      'Credited work': approved ? record.netWorkedMinutes : 0,
      'Credited overtime': approved ? record.overtimeMinutes : 0,
    };
    return ExpansionTile(
      key: Key('attendance-breakdown-${record.id}'),
      tilePadding: EdgeInsets.zero,
      title: Text(context.tr('How this day was calculated')),
      children: [
        for (final row in rows.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(context.tr(row.key))),
                const SizedBox(width: 12),
                Text(duration(row.value)),
              ],
            ),
          ),
        Text(
          context.tr(
            'Credited hours require approved, completed attendance. Lateness is made up before post-shift overtime; unused break overtime applies only to on-time arrivals.',
          ),
        ),
        if (record.dayDecisionReason != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.tr('Manager decision reason')),
            subtitle: Text(record.dayDecisionReason!),
          ),
      ],
    );
  }
}
