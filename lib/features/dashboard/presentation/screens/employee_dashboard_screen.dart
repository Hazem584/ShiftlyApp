import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';
import 'package:shiftly/features/dashboard/data/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/dashboard_loading.dart';

part 'parts/employee_dashboard_screen/private_employee_dashboard.dart';
part 'parts/employee_dashboard_screen/private_shift_card.dart';
part 'parts/employee_dashboard_screen/private_count_card.dart';

class EmployeeDashboardScreen extends StatelessWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) => switch (state) {
          DashboardLoading() => const DashboardLoadingView(),
          DashboardLoaded(:final data) when data is EmployeeDashboardData =>
            _EmployeeDashboard(data: data, state: state),
          DashboardLoaded() => const SizedBox.shrink(),
          DashboardError(:final failure) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load your overview',
            message: failure.message,
            action: FilledButton.icon(
              onPressed: context.read<DashboardCubit>().load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ),
        },
      );
}

String _leaveType(LeaveRequestType type) => switch (type) {
  LeaveRequestType.annualLeave => 'Annual leave',
  LeaveRequestType.sickLeave => 'Sick leave',
  LeaveRequestType.emergencyLeave => 'Emergency leave',
  LeaveRequestType.earlyLeave => 'Early leave',
  LeaveRequestType.other => 'Other leave',
  LeaveRequestType.unknown => 'Leave request',
};

String _leaveStatus(LeaveRequestStatus status) => switch (status) {
  LeaveRequestStatus.pending => 'Pending',
  LeaveRequestStatus.approved => 'Approved',
  LeaveRequestStatus.rejected => 'Rejected',
  LeaveRequestStatus.cancelled => 'Cancelled',
  LeaveRequestStatus.unknown => 'Updated',
};
