import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/core/widgets/screen_header.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit.dart';
import 'package:shiftly/features/shifts/data/shift_repository.dart';
import 'package:shiftly/features/shifts/presentation/cubit/manager_shifts_cubit.dart';
import 'package:shiftly/features/shifts/presentation/widgets/shift_card.dart';
import 'package:shiftly/features/shifts/presentation/widgets/shift_editor_dialog.dart';

class ManagerShiftsScreen extends StatelessWidget {
  const ManagerShiftsScreen({this.timezone = 'Etc/UTC', super.key});

  final String timezone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<ManagerShiftsCubit, ManagerShiftsState>(
          listenWhen: (previous, current) =>
              previous.failure != current.failure && current.failure != null,
          listener: (context, state) =>
              ToastService.error(context, message: state.failure!.message),
          builder: (context, state) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                child: ScreenHeader(
                  title: 'Shift Management',
                  subtitle: 'Schedule and manage employee shifts',
                  action: FilledButton.icon(
                    key: const Key('create-shift'),
                    onPressed: state.creating
                        ? null
                        : () => _create(context, timezone),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Create'),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: DropdownButtonFormField<ShiftStatus?>(
                  key: const Key('shift-status-filter'),
                  initialValue: state.query.status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.filter_list_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All shifts')),
                    DropdownMenuItem(
                      value: ShiftStatus.scheduled,
                      child: Text('Scheduled'),
                    ),
                    DropdownMenuItem(
                      value: ShiftStatus.completed,
                      child: Text('Completed'),
                    ),
                    DropdownMenuItem(
                      value: ShiftStatus.cancelled,
                      child: Text('Cancelled'),
                    ),
                  ],
                  onChanged: (status) => context
                      .read<ManagerShiftsCubit>()
                      .load(query: ShiftQuery(status: status)),
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Expanded(child: _body(context, state, timezone)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    ManagerShiftsState state,
    String timezone,
  ) {
    if (state.initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.records.isEmpty) {
      return EmptyState(
        icon: state.failure == null
            ? Icons.event_available_outlined
            : Icons.cloud_off_outlined,
        title: state.failure == null
            ? 'No shifts yet'
            : 'Could not load shifts',
        message:
            state.failure?.message ??
            'Create a shift for an active employee to get started.',
        action: state.failure == null
            ? null
            : FilledButton(
                onPressed: context.read<ManagerShiftsCubit>().load,
                child: const Text('Retry'),
              ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<ManagerShiftsCubit>().load(refresh: true),
      child: ListView.separated(
        key: const Key('manager-shifts-list'),
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
        itemCount: state.records.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == state.records.length) {
            return OutlinedButton(
              onPressed: state.loadingMore
                  ? null
                  : context.read<ManagerShiftsCubit>().loadMore,
              child: state.loadingMore
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Load more'),
            );
          }
          final shift = state.records[index];
          return ShiftCard(
            key: Key('manager-shift-${shift.id}'),
            shift: shift,
            timezone: timezone,
            trailing:
                state.cancellingId == shift.id || state.updatingId == shift.id
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: () => _openDetails(context, shift.id, timezone),
          );
        },
      ),
    );
  }

  List<Employee> _activeEmployees(BuildContext context) {
    final state = context.read<EmployeesCubit>().state;
    if (state is! EmployeesLoaded) return const [];
    return state.employees
        .where(
          (employee) =>
              employee.employmentStatus == EmploymentStatus.active &&
              employee.role == EmployeeRole.employee,
        )
        .toList(growable: false);
  }

  Future<void> _create(BuildContext context, String timezone) async {
    final employees = _activeEmployees(context);
    if (employees.isEmpty) {
      ToastService.error(
        context,
        message: 'Add or activate an employee before creating a shift.',
      );
      return;
    }
    final value = await showDialog<ShiftEditorValue>(
      context: context,
      builder: (_) =>
          ShiftEditorDialog(employees: employees, timezone: timezone),
    );
    if (value == null || !context.mounted) return;
    final result = await context.read<ManagerShiftsCubit>().create(
      CreateShiftInput(
        employeeMembershipId: value.employeeMembershipId,
        startsAt: value.startsAt,
        endsAt: value.endsAt,
        breakMinutes: value.breakMinutes,
        graceMinutes: value.graceMinutes,
        notes: value.notes,
      ),
    );
    if (context.mounted && result == ShiftMutationResult.success) {
      ToastService.success(context, message: 'Shift created successfully.');
    }
  }

  Future<void> _openDetails(
    BuildContext context,
    String shiftId,
    String timezone,
  ) async {
    final record = await context.read<ManagerShiftsCubit>().loadDetails(
      shiftId,
    );
    if (record == null || !context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                record.employee.displayName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.s),
              ShiftStatusBadge(status: record.status),
              const SizedBox(height: AppSpacing.m),
              Text(
                'Starts: ${WorkspaceTime.dateTime(record.startsAt, timezone)}',
              ),
              Text('Ends: ${WorkspaceTime.dateTime(record.endsAt, timezone)}'),
              Text('Break: ${record.breakMinutes} minutes'),
              Text('Clock-in grace: ${record.graceMinutes} minutes'),
              if (record.notes != null) ...[
                const SizedBox(height: AppSpacing.s),
                Text(record.notes!),
              ],
              if (record.canManage) ...[
                const SizedBox(height: AppSpacing.l),
                OutlinedButton.icon(
                  key: const Key('edit-shift'),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _edit(context, record, timezone);
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit shift'),
                ),
                const SizedBox(height: AppSpacing.s),
                FilledButton.icon(
                  key: const Key('cancel-shift'),
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    await _cancel(context, record.id);
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel shift'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    ShiftRecord record,
    String timezone,
  ) async {
    final employees = _activeEmployees(context);
    final value = await showDialog<ShiftEditorValue>(
      context: context,
      builder: (_) => ShiftEditorDialog(
        employees: employees,
        timezone: timezone,
        initial: record,
      ),
    );
    if (value == null || !context.mounted) return;
    final result = await context.read<ManagerShiftsCubit>().update(
      record.id,
      UpdateShiftInput(
        employeeMembershipId: value.employeeMembershipId,
        startsAt: value.startsAt,
        endsAt: value.endsAt,
        breakMinutes: value.breakMinutes,
        graceMinutes: value.graceMinutes,
        notes: value.notes,
      ),
    );
    if (context.mounted && result == ShiftMutationResult.success) {
      ToastService.success(context, message: 'Shift updated successfully.');
    }
  }

  Future<void> _cancel(BuildContext context, String shiftId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel shift?'),
        content: const Text(
          'The shift will remain in history with a cancelled status.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep shift'),
          ),
          FilledButton(
            key: const Key('confirm-cancel-shift'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel shift'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await context.read<ManagerShiftsCubit>().cancel(shiftId);
    if (context.mounted && result == ShiftMutationResult.success) {
      ToastService.success(context, message: 'Shift cancelled.');
    }
  }
}
