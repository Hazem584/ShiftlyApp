import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/utils/leave_requests_panel_formatters.dart';

class LeaveRequestFilters extends StatelessWidget {
  const LeaveRequestFilters({super.key, required this.state});
  final LeaveRequestsState state;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 8,
    children: [
      DropdownButton<LeaveRequestStatus?>(
        value: state.query.status,
        hint: Text(context.tr('All statuses')),
        items: [
          DropdownMenuItem(
            value: null,
            child: Text(context.tr('All statuses')),
          ),
          DropdownMenuItem(
            value: LeaveRequestStatus.pending,
            child: Text(context.tr('Pending')),
          ),
          DropdownMenuItem(
            value: LeaveRequestStatus.approved,
            child: Text(context.tr('Approved')),
          ),
          DropdownMenuItem(
            value: LeaveRequestStatus.rejected,
            child: Text(context.tr('Rejected')),
          ),
          DropdownMenuItem(
            value: LeaveRequestStatus.cancelled,
            child: Text(context.tr('Cancelled')),
          ),
        ],
        onChanged: (status) => context.read<LeaveRequestsCubit>().load(
          query: leaveRequestsPanelQuery(
            state.query,
            status: status,
            replaceStatus: true,
          ),
        ),
      ),
      DropdownButton<LeaveRequestType?>(
        value: state.query.type,
        hint: Text(context.tr('All types')),
        items: [
          DropdownMenuItem(value: null, child: Text(context.tr('All types'))),
          DropdownMenuItem(
            value: LeaveRequestType.annualLeave,
            child: Text(context.tr('Annual')),
          ),
          DropdownMenuItem(
            value: LeaveRequestType.sickLeave,
            child: Text(context.tr('Sick')),
          ),
          DropdownMenuItem(
            value: LeaveRequestType.emergencyLeave,
            child: Text(context.tr('Emergency')),
          ),
          DropdownMenuItem(
            value: LeaveRequestType.earlyLeave,
            child: Text(context.tr('Early departure')),
          ),
          DropdownMenuItem(
            value: LeaveRequestType.other,
            child: Text(context.tr('Other')),
          ),
        ],
        onChanged: (type) => context.read<LeaveRequestsCubit>().load(
          query: leaveRequestsPanelQuery(
            state.query,
            type: type,
            replaceType: true,
          ),
        ),
      ),
    ],
  );
}
