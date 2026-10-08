import 'package:flutter/material.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/shift_templates_screen.dart';

/// Compatibility wrapper for callers of the retired assignment screen.
class ManagerShiftsScreen extends StatelessWidget {
  const ManagerShiftsScreen({this.timezone = 'Etc/UTC', super.key});
  final String timezone;
  @override
  Widget build(BuildContext context) =>
      ShiftTemplatesScreen(timezone: timezone);
}
