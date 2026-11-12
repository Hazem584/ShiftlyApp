import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/theme/employee_design.dart';

class EmployeeAppearance extends StatelessWidget {
  const EmployeeAppearance({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCoordinator?>();
    if (session?.state.status != SessionStatus.authenticatedEmployee) {
      return child;
    }
    return Theme(
      data: EmployeeDesign.theme(
        Theme.of(context),
        arabic: Localizations.localeOf(context).languageCode == 'ar',
      ),
      child: KeyedSubtree(
        key: ValueKey(
          "${session?.state.currentUser?.id}:${session?.state.activeMembership?.id}",
        ),
        child: child,
      ),
    );
  }
}
