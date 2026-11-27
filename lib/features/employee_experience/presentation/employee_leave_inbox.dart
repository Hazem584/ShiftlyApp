import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_form_dialog.dart';

import 'employee_leave_request_list.dart';

class EmployeeLeaveInbox extends StatelessWidget {
  const EmployeeLeaveInbox({required this.timezone, super.key});
  final String timezone;
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<EmployeeLeaveRequestsCubit, EmployeeLeaveRequestsState>(
    builder: (context, state) {
      final cubit = context.read<EmployeeLeaveRequestsCubit>();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(context.tr('All requests')),
                ),
                ButtonSegment(value: true, label: Text(context.tr('Pending'))),
              ],
              selected: {state.query.status == LeaveRequestStatus.pending},
              onSelectionChanged: state.refreshing
                  ? null
                  : (selection) => cubit.load(
                      query: LeaveRequestQuery(
                        status: selection.first
                            ? LeaveRequestStatus.pending
                            : null,
                      ),
                    ),
            ),
          ),
          Expanded(
            child: EmployeeLeaveRequestList(state: state, timezone: timezone),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: FilledButton(
                key: const Key('request-leave'),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: LeaveRequestFormDialog(timezone: timezone),
                  ),
                ),
                child: Text(context.tr('Request leave')),
              ),
            ),
          ),
        ],
      );
    },
  );
}
