import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        hint: const Text('All statuses'),
        items: const [
          DropdownMenuItem(value: null, child: Text('All statuses')),
          DropdownMenuItem(
            value: LeaveRequestStatus.pending,
            child: Text('Pending'),
          ),
          DropdownMenuItem(
            value: LeaveRequestStatus.approved,
            child: Text('Approved'),
          ),
          DropdownMenuItem(
            value: LeaveRequestStatus.rejected,
            child: Text('Rejected'),
          ),
          DropdownMenuItem(
            value: LeaveRequestStatus.cancelled,
            child: Text('Cancelled'),
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
        hint: const Text('All types'),
        items: const [
          DropdownMenuItem(value: null, child: Text('All types')),
          DropdownMenuItem(
            value: LeaveRequestType.annualLeave,
            child: Text('Annual'),
          ),
          DropdownMenuItem(
            value: LeaveRequestType.sickLeave,
            child: Text('Sick'),
          ),
          DropdownMenuItem(
            value: LeaveRequestType.emergencyLeave,
            child: Text('Emergency'),
          ),
          DropdownMenuItem(
            value: LeaveRequestType.earlyLeave,
            child: Text('Early departure'),
          ),
          DropdownMenuItem(value: LeaveRequestType.other, child: Text('Other')),
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
