import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/extra_authorization.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_dialog.dart';

import '../cubit/extra_shifts_cubit.dart';
import 'extra_shift_form.dart';

Future<void> showExtraShiftForm(
  BuildContext context, {
  required String workspaceId,
  required String timezone,
  required bool actual,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => ExtraShiftForm(
    repository: getIt<FixedShiftRepository>(),
    cubit: context.read<ExtraShiftsCubit>(),
    workspaceId: workspaceId,
    timezone: timezone,
    actual: actual,
  ),
);
Future<void> revokeExtraShift(
  BuildContext context,
  ExtraAuthorization value,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (c) => ManagerDialog(
      title: Text(context.tr('Revoke extra authorization?')),
      content: Text(
        context.tr(
          '{value1} · {value2}\nThis removes permission to start this extra shift. Attendance already recorded will be kept.',
          {
            'value1': (value.schedule.name).toString(),
            'value2': (value.operationalDate).toString(),
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(c, true),
          child: Text(context.tr('Revoke')),
        ),
      ],
    ),
  );
  if (context.mounted && confirmed == true) {
    await context.read<ExtraShiftsCubit>().revoke(value);
  }
}
