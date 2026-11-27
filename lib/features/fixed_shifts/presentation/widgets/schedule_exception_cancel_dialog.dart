import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_dialog.dart';

Future<List<ShiftTemplate>> loadTemplatesForScheduleException({
  required FixedShiftRepository fixedShifts,
  required String workspaceId,
  required String? employeeMembershipId,
  required bool Function() isAlive,
}) async {
  final templates = <ShiftTemplate>[];
  if (employeeMembershipId == null) return templates;
  for (var page = 1; ; page++) {
    final result = await fixedShifts.listTemplates(workspaceId, page: page);
    if (!isAlive()) return templates;
    templates.addAll(result.data.where((e) => e.active));
    if (page >= result.pagination.totalPages) break;
  }
  return templates;
}

Future<String?> showCancelScheduleExceptionDialog(BuildContext context) async {
  final controller = TextEditingController();
  final reason = await showDialog<String>(
    context: context,
    builder: (dialogContext) => ManagerDialog(
      title: Text(context.tr('Cancel day exception?')),
      content: TextField(
        controller: controller,
        autofocus: true,
        minLines: 2,
        maxLines: 4,
        maxLength: 1000,
        decoration: InputDecoration(
          labelText: context.tr('Cancellation reason (at least 5 characters)'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(context.tr('Keep exception')),
        ),
        FilledButton(
          onPressed: () {
            if (controller.text.trim().length >= 5) {
              Navigator.pop(dialogContext, controller.text.trim());
            }
          },
          child: Text(context.tr('Cancel exception')),
        ),
      ],
    ),
  );
  Future<void>.delayed(const Duration(seconds: 1), controller.dispose);
  return reason;
}
