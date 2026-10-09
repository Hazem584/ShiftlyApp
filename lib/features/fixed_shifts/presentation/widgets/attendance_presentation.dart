import 'package:flutter/material.dart';

import '../../data/fixed_shift_repository.dart';

String attendanceClassificationLabel(AttendanceClassification value) =>
    switch (value) {
      AttendanceClassification.early => 'Early',
      AttendanceClassification.onTime => 'On time',
      AttendanceClassification.late => 'Late',
      AttendanceClassification.unknown => 'Status unavailable',
    };
IconData attendanceClassificationIcon(AttendanceClassification value) =>
    switch (value) {
      AttendanceClassification.early => Icons.fast_forward_rounded,
      AttendanceClassification.onTime => Icons.check_circle_outline,
      AttendanceClassification.late => Icons.warning_amber_rounded,
      AttendanceClassification.unknown => Icons.help_outline_rounded,
    };
String attendanceElapsed(Duration value) {
  final safe = value.isNegative ? Duration.zero : value;
  return '${safe.inHours}h ${safe.inMinutes.remainder(60)}m';
}

Color attendanceTemplateColor(String value) {
  final hex = value.replaceFirst('#', '');
  return hex.length == 6
      ? Color(int.tryParse('FF$hex', radix: 16) ?? 0xFF334155)
      : const Color(0xFF334155);
}
