import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_list.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_pending_invitations.dart';

class EmployeesLoadedBody extends StatelessWidget {
  const EmployeesLoadedBody({
    required this.state,
    required this.onShift,
    required this.onInvite,
    super.key,
  });

  final EmployeesLoaded state;
  final bool onShift;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EmployeesCubit>();
    final visible = state.employees
        .where(
          (e) =>
              !onShift ||
              e.attendanceStatus == AttendanceStatus.present ||
              e.attendanceStatus == AttendanceStatus.late,
        )
        .toList();
    final emptyQuery = state.query.isEmpty;
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
                  icon: emptyQuery
                      ? Icons.group_add_outlined
                      : Icons.person_search_outlined,
                  title: emptyQuery
                      ? 'No employees yet'
                      : 'No matching employees',
                  message: emptyQuery
                      ? 'Invite your first team member to get started.'
                      : 'Try another name or clear your search.',
                  action: emptyQuery
                      ? FilledButton.icon(
                          onPressed: onInvite,
                          icon: const Icon(Icons.add_rounded),
                          label: Text(context.tr('Invite employee')),
                        )
                      : null,
                )
              : EmployeeList(
                  employees: visible,
                  hasMore: state.hasMore,
                  loadingMore: state.loadingMore,
                  onLoadMore: cubit.loadMore,
                  onRefresh: () => cubit.load(
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
