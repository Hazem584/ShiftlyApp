import 'package:flutter/material.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_content.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({this.initialTab = 0, super.key});

  final int initialTab;

  @override
  Widget build(BuildContext context) =>
      AttendanceContent(initialTab: initialTab);
}
