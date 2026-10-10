import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';

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
String attendanceElapsed(Duration value, [BuildContext? context]) {
  final safe = value.isNegative ? Duration.zero : value;
  return context == null
      ? '${safe.inHours}h ${safe.inMinutes.remainder(60)}m'
      : context.tr('{hours}h {minutes}m', {
          'hours': '${safe.inHours}',
          'minutes': '${safe.inMinutes.remainder(60)}',
        });
}

Color attendanceTemplateColor(String value) {
  final hex = value.replaceFirst('#', '');
  return hex.length == 6
      ? Color(int.tryParse('FF$hex', radix: 16) ?? 0xFF334155)
      : const Color(0xFF334155);
}
