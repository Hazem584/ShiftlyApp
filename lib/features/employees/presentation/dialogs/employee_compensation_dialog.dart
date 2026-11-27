import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';
import 'package:shiftly/features/employees/presentation/cubit/employee_details_cubit.dart';

Future<void> showEmployeeCompensationDialog(
  BuildContext context, {
  required String workspaceId,
  required String membershipId,
  required Employee employee,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _EmployeeCompensationDialog(
      workspaceId: workspaceId,
      membershipId: membershipId,
      employee: employee,
    ),
  );
  if (saved == true && context.mounted) {
    await context.read<EmployeeDetailsCubit>().load(
      workspaceId: workspaceId,
      membershipId: membershipId,
      retain: true,
    );
    if (context.mounted) {
      ToastService.success(context, message: 'Compensation updated');
    }
  }
}

class _EmployeeCompensationDialog extends StatefulWidget {
  const _EmployeeCompensationDialog({
    required this.workspaceId,
    required this.membershipId,
    required this.employee,
  });
  final String workspaceId, membershipId;
  final Employee employee;
  @override
  State<_EmployeeCompensationDialog> createState() =>
      _EmployeeCompensationDialogState();
}

class _EmployeeCompensationDialogState
    extends State<_EmployeeCompensationDialog> {
  late final _monthly = TextEditingController(
    text: widget.employee.monthlySalary?.toStringAsFixed(2) ?? '',
  );
  late final _hourly = TextEditingController(
    text: widget.employee.hourlyRate?.toStringAsFixed(2) ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _monthly.dispose();
    _hourly.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final monthly = double.tryParse(_monthly.text.trim());
    final hourly = double.tryParse(_hourly.text.trim());
    setState(() => _saving = true);
    try {
      await getIt<EmployeeRepository>().updateCompensation(
        workspaceId: widget.workspaceId,
        membershipId: widget.membershipId,
        monthlySalary: monthly,
        hourlyRate: hourly ?? (monthly != null ? monthly / 176.0 : null),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ToastService.error(context, message: 'Could not update compensation.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr('Salary & hourly rate')),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _monthly,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: context.tr('Monthly salary'),
            helperText: context.tr('Auto-calculates hourly rate (÷ 176 hrs)'),
          ),
          onChanged: (v) {
            final m = double.tryParse(v.trim());
            if (m != null && m > 0) {
              _hourly.text = (m / 176.0).toStringAsFixed(2);
            }
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _hourly,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: context.tr('Hourly rate'),
            helperText: context.tr(
              'Used for overtime, extra shifts & lateness',
            ),
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(false),
        child: Text(context.tr('Cancel')),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(context.tr('Save')),
      ),
    ],
  );
}
