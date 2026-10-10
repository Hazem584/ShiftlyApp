import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/dashboard_loading.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/employee_dashboard_view.dart';

class EmployeeDashboardScreen extends StatelessWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) => switch (state) {
          DashboardLoading() => const DashboardLoadingView(),
          DashboardLoaded(:final data) when data is EmployeeDashboardData =>
            EmployeeDashboardView(data: data, state: state),
          DashboardLoaded() => const SizedBox.shrink(),
          DashboardError(:final failure) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load your overview',
            message: failure.message,
            action: FilledButton.icon(
              onPressed: context.read<DashboardCubit>().load,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.tr('Try again')),
            ),
          ),
        },
      );
}
