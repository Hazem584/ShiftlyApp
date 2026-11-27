import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/utils/leave_request_display_formatters.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_date_button.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_time_button.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_notice.dart';

Widget buildLeaveRequestFormFields({
  required BuildContext context,
  required LeaveRequestType type,
  required DateTime startDate,
  required DateTime endDate,
  required TimeOfDay startTime,
  required TimeOfDay endTime,
  required TextEditingController reasonController,
  required ValueChanged<LeaveRequestType?> onTypeChanged,
  required VoidCallback onPickStartDate,
  required VoidCallback onPickEndDate,
  required VoidCallback onPickStartTime,
  required VoidCallback onPickEndTime,
}) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    DropdownButtonFormField<LeaveRequestType>(
      key: const Key('leave-type'),
      initialValue: type,
      decoration: InputDecoration(labelText: context.tr('Leave type')),
      items: LeaveRequestType.values
          .where((item) => item != LeaveRequestType.unknown)
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(context.tr(leaveTypeLabel(item))),
            ),
          )
          .toList(),
      onChanged: onTypeChanged,
    ),
    const SizedBox(height: 12),
    LeaveRequestDateButton(
      label: context.tr('Start date'),
      value: startDate,
      onPressed: onPickStartDate,
    ),
    const SizedBox(height: 8),
    LeaveRequestDateButton(
      label: context.tr('End date'),
      value: endDate,
      onPressed: type == LeaveRequestType.earlyLeave ? null : onPickEndDate,
    ),
    if (type == LeaveRequestType.earlyLeave) ...[
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: LeaveRequestTimeButton(
              label: context.tr('Start time'),
              value: startTime,
              onPressed: onPickStartTime,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LeaveRequestTimeButton(
              label: context.tr('End time'),
              value: endTime,
              onPressed: onPickEndTime,
            ),
          ),
        ],
      ),
    ],
    const SizedBox(height: 12),
    TextFormField(
      key: const Key('leave-reason'),
      controller: reasonController,
      maxLength: 1000,
      maxLines: 4,
      decoration: InputDecoration(labelText: context.tr('Reason')),
      validator: (value) => value?.trim().isEmpty != false
          ? context.tr('A reason is required')
          : null,
    ),
    const SizedBox(height: 20),
    EmployeeNotice(
      child: Text(
        context.tr(
          'Your manager will review this request. It is pending until approved.',
        ),
      ),
    ),
  ],
);
