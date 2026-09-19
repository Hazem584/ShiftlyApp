import 'package:flutter/material.dart';
import 'package:shiftly/core/widgets/feature_placeholder.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Attendance',
      icon: Icons.fact_check_outlined,
      message: 'Daily records and shift monitoring will appear here in a future sprint.',
    );
  }
}
