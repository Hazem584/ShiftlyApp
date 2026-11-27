import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/employee_design.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';

class EmployeeAttendanceRecoverySection extends StatelessWidget {
  const EmployeeAttendanceRecoverySection({
    required this.clientAttendanceId,
    required this.busy,
    super.key,
  });

  final String clientAttendanceId;
  final bool busy;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 12),
      Text(
        context.tr('Original request saved'),
        style: const TextStyle(color: EmployeeDesign.mint),
      ),
      SelectableText(
        clientAttendanceId,
        style: const TextStyle(color: Colors.white),
      ),
      const SizedBox(height: 10),
      FilledButton(
        onPressed: busy
            ? null
            : () => context.read<FlexibleAttendanceCubit>().recoverClockIn(),
        child: Text(context.tr('Check original request')),
      ),
      TextButton(
        onPressed: () =>
            Clipboard.setData(ClipboardData(text: clientAttendanceId)),
        child: Text(
          context.tr('Copy request reference'),
          style: const TextStyle(color: EmployeeDesign.mint),
        ),
      ),
      TextButton(
        onPressed: () => context.push('/support'),
        child: Text(
          context.tr('Get help'),
          style: const TextStyle(color: EmployeeDesign.mint),
        ),
      ),
    ],
  );
}
