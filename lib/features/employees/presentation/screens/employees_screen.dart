import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit.dart';
import 'package:shiftly/features/employees/presentation/screens/employees_loaded_body.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_search_bar.dart';
import 'package:shiftly/features/employees/presentation/widgets/employees_loading.dart';

import 'employees_screen_heading.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({this.embedded = false, super.key});
  final bool embedded;
  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  bool _onShift = false;

  Future<void> _openAddEmployee(BuildContext context) async {
    final added = await context.push<bool>('/employees/add');
    if (added == true && context.mounted) {
      ToastService.success(context, message: 'Invitation created successfully');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: BlocBuilder<EmployeesCubit, EmployeesState>(
        builder: (context, s) {
          final cubit = context.read<EmployeesCubit>();
          final loaded = s is EmployeesLoaded ? s : null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EmployeesScreenHeading(total: loaded?.total),
              EmployeeSearchBar(
                onShift: _onShift,
                onShiftChanged: (v) => setState(() => _onShift = v),
                status: loaded?.status,
                onChanged: (q) => cubit.load(query: q, status: loaded?.status),
                onStatusChanged: (st) =>
                    cubit.load(query: loaded?.query ?? '', status: st),
              ),
              Expanded(child: _stateBody(context, s)),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('invite-employee'),
                    onPressed: () => _openAddEmployee(context),
                    child: Text(context.tr('Invite employee')),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _stateBody(BuildContext context, EmployeesState state) =>
      switch (state) {
        EmployeesLoading() => const EmployeesLoadingView(),
        EmployeesError(:final message) => EmptyState(
          icon: Icons.cloud_off_outlined,
          title: context.tr('Could not load employees'),
          message: message,
          action: FilledButton(
            onPressed: context.read<EmployeesCubit>().load,
            child: Text(context.tr('Retry')),
          ),
        ),
        EmployeesLoaded() => EmployeesLoadedBody(
          state: state,
          onShift: _onShift,
          onInvite: () => _openAddEmployee(context),
        ),
      };
}
