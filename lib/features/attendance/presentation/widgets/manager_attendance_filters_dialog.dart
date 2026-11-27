import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/manager_attendance_filter_helpers.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_dialog.dart';

Future<void> showManagerAttendanceFilters(
  BuildContext context,
  ManagerAttendanceState state,
  String timezone,
) async {
  final employees = activeAttendanceEmployees(context);
  var employeeId = state.query.employeeMembershipId;
  var dates = initialAttendanceDateRange(state, timezone);
  final query = await showDialog<AttendanceQuery>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => ManagerDialog(
        title: Text(context.tr('Attendance filters')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String?>(
              initialValue: employeeId,
              decoration: InputDecoration(labelText: context.tr('Employee')),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(context.tr('All employees')),
                ),
                for (final employee in employees)
                  DropdownMenuItem(
                    value: employee.id,
                    child: Text(employee.displayName),
                  ),
              ],
              onChanged: (value) => setDialogState(() => employeeId = value),
            ),
            const SizedBox(height: AppSpacing.m),
            OutlinedButton.icon(
              onPressed: () async {
                final now = WorkspaceTime.inWorkspace(
                  DateTime.now().toUtc(),
                  timezone,
                );
                final selected = await showDateRangePicker(
                  context: dialogContext,
                  firstDate: DateTime(now.year - 3),
                  lastDate: DateTime(now.year + 3, 12, 31),
                  initialDateRange: dates,
                );
                if (selected != null) setDialogState(() => dates = selected);
              },
              icon: const Icon(Icons.date_range_outlined),
              label: Text(formatAttendanceDateRangeLabel(context, dates)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              AttendanceQuery(reviewStatus: state.query.reviewStatus),
            ),
            child: Text(context.tr('Clear')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              buildFilteredAttendanceQuery(
                state: state,
                employeeId: employeeId,
                dates: dates,
                timezone: timezone,
              ),
            ),
            child: Text(context.tr('Apply')),
          ),
        ],
      ),
    ),
  );
  if (query != null && context.mounted) {
    await context.read<ManagerAttendanceCubit>().load(query: query);
  }
}
