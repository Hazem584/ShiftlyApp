import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/correction_request_dialog.dart';

import 'employee_page.dart';
import 'employee_record_body.dart';

class EmployeeRecordScreen extends StatelessWidget {
  const EmployeeRecordScreen({
    required this.record,
    required this.timezone,
    super.key,
  });
  final AttendanceRecordApi record;
  final String timezone;
  @override
  Widget build(BuildContext context) {
    final zone = record.workspaceTimezone ?? timezone;
    return EmployeePage(
      title: 'My record',
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (record.clockOutAt != null &&
              record.reviewStatus != AttendanceReviewStatus.rejected)
            FilledButton(
              onPressed: () async {
                final sent = await showCorrectionRequest(context, record, zone);
                if (sent == true && context.mounted) {
                  context.push('/team-work?tab=corrections');
                }
              },
              child: Text(context.tr('Request correction')),
            ),
          TextButton(
            onPressed: () => context.push('/team-work?tab=corrections'),
            child: Text(context.tr('My correction history')),
          ),
        ],
      ),
      child: EmployeeRecordBody(record: record, zone: zone),
    );
  }
}
