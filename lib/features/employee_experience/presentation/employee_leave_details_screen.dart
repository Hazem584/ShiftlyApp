import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/confirm_action.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';

import 'employee_leave_details_body.dart';
import 'employee_page.dart';

class EmployeeLeaveDetailsScreen extends StatefulWidget {
  const EmployeeLeaveDetailsScreen({
    required this.request,
    required this.timezone,
    super.key,
  });
  final LeaveRequestRecord request;
  final String timezone;
  @override
  State<EmployeeLeaveDetailsScreen> createState() =>
      _EmployeeLeaveDetailsScreenState();
}

class _EmployeeLeaveDetailsScreenState
    extends State<EmployeeLeaveDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<EmployeeLeaveRequestsCubit>().loadDetails(
          widget.request.id,
        );
      }
    });
  }

  Future<void> _cancel() async {
    final cubit = context.read<EmployeeLeaveRequestsCubit>();
    final ok = await confirmAction(
      context,
      title: 'Cancel leave request?',
      message: context.tr(
        'This request will no longer be available for manager approval.',
      ),
      action: 'Cancel request',
      actionKey: 'confirm-cancel-leave',
    );
    if (!ok || !mounted) return;
    final result = await cubit.cancel(widget.request.id);
    if (mounted && result == LeaveMutationResult.failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cubit.state.failure?.message ??
                context.tr('Could not cancel request'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<EmployeeLeaveRequestsCubit, EmployeeLeaveRequestsState>(
        builder: (context, state) {
          final request = state.selected?.id == widget.request.id
              ? state.selected!
              : state.requests
                        .where((r) => r.id == widget.request.id)
                        .firstOrNull ??
                    widget.request;
          final busy = state.cancellingIds.contains(request.id);
          return EmployeePage(
            title: 'Request details',
            footer: request.canCancel
                ? FilledButton(
                    key: Key('cancel-${request.id}'),
                    onPressed: busy ? null : _cancel,
                    child: Text(
                      context.tr(busy ? 'Saving…' : 'Cancel request'),
                    ),
                  )
                : null,
            child: EmployeeLeaveDetailsBody(
              request: request,
              state: state,
              timezone: widget.timezone,
            ),
          );
        },
      );
}
