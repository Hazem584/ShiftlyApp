import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_list.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_pending_invitations.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_search_bar.dart';
import 'package:shiftly/features/employees/presentation/widgets/employees_loading.dart';

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
        builder: (context, state) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Your team'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state is EmployeesLoaded
                          ? context.tr('{count} people', {
                              'count': '${state.total}',
                            })
                          : context.tr('Manage your workspace team'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            EmployeeSearchBar(
              onShift: _onShift,
              onShiftChanged: (value) => setState(() => _onShift = value),
              status: state is EmployeesLoaded ? state.status : null,
              onChanged: (query) => context.read<EmployeesCubit>().load(
                query: query,
                status: state is EmployeesLoaded ? state.status : null,
              ),
              onStatusChanged: (status) => context.read<EmployeesCubit>().load(
                query: state is EmployeesLoaded ? state.query : '',
                status: status,
              ),
            ),
            Expanded(child: _stateBody(context, state)),
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
        ),
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
            onPressed: () => context.read<EmployeesCubit>().load(),
            child: Text(context.tr('Retry')),
          ),
        ),
        EmployeesLoaded() => _loadedBody(context, state),
      };

  Widget _loadedBody(BuildContext context, EmployeesLoaded state) {
    final visible = state.employees
        .where(
          (employee) =>
              !_onShift ||
              employee.attendanceStatus == AttendanceStatus.present ||
              employee.attendanceStatus == AttendanceStatus.late,
        )
        .toList();
    return Column(
      children: [
        if (state.pendingInvitations.isNotEmpty)
          EmployeePendingInvitations(invitations: state.pendingInvitations),
        if (state.failure != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              state.failure!.message,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        Expanded(
          child: visible.isEmpty
              ? EmptyState(
                  icon: state.query.isEmpty
                      ? Icons.group_add_outlined
                      : Icons.person_search_outlined,
                  title: state.query.isEmpty
                      ? 'No employees yet'
                      : 'No matching employees',
                  message: state.query.isEmpty
                      ? 'Invite your first team member to get started.'
                      : 'Try another name or clear your search.',
                  action: state.query.isEmpty
                      ? FilledButton.icon(
                          onPressed: () => _openAddEmployee(context),
                          icon: const Icon(Icons.add_rounded),
                          label: Text(context.tr('Invite employee')),
                        )
                      : null,
                )
              : EmployeeList(
                  employees: visible,
                  hasMore: state.hasMore,
                  loadingMore: state.loadingMore,
                  onLoadMore: context.read<EmployeesCubit>().loadMore,
                  onRefresh: () => context.read<EmployeesCubit>().load(
                    query: state.query,
                    status: state.status,
                    refresh: true,
                  ),
                ),
        ),
      ],
    );
  }
}
