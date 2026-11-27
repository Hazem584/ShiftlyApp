import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:shiftly/features/shifts/presentation/cubit/employee_shifts_cubit.dart';
import 'package:shiftly/features/shifts/presentation/widgets/employee_shift_details_info.dart';

Future<void> showEmployeeShiftDetailsSheet(
  BuildContext context,
  String shiftId,
  String timezone,
) async {
  final record = await context.read<EmployeeShiftsCubit>().loadDetails(shiftId);
  if (record == null || !context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => EmployeeShiftDetailsSheet(
      record: record,
      timezone: timezone,
      sheetContext: sheetContext,
    ),
  );
}

class EmployeeShiftDetailsSheet extends StatelessWidget {
  const EmployeeShiftDetailsSheet({
    required this.record,
    required this.timezone,
    required this.sheetContext,
    super.key,
  });

  final ShiftRecord record;
  final String timezone;
  final BuildContext sheetContext;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...buildEmployeeShiftDetailInfo(context, record, timezone),
          if (record.canClockOut) ...[
            const SizedBox(height: AppSpacing.l),
            _buildClockOutButton(context),
          ],
        ],
      ),
    ),
  );

  Widget _buildClockOutButton(BuildContext context) =>
      BlocBuilder<EmployeeShiftsCubit, EmployeeShiftsState>(
        builder: (context, state) {
          final busy = state.clockingOutIds.contains(record.id);
          return FilledButton.icon(
            key: Key('clock-out-${record.id}'),
            onPressed: busy ? null : () => _clockOut(context),
            icon: busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.fingerprint_rounded),
            label: Text(context.tr('Clock out')),
          );
        },
      );

  Future<void> _clockOut(BuildContext context) async {
    final result = await context.read<EmployeeShiftsCubit>().clockOut(
      record.id,
    );
    if (!context.mounted) return;
    if (result == ClockMutationResult.success) {
      Navigator.pop(sheetContext);
      ToastService.success(context, message: 'Clock-out recorded.');
    }
  }
}
