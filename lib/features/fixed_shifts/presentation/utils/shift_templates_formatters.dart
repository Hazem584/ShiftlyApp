import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';

TimeOfDay shiftTemplatesScreenTod(int minute) =>
    TimeOfDay(hour: minute ~/ 60, minute: minute % 60);

String shiftTemplatesScreenDuration(int minutes) =>
    '${minutes ~/ 60}h ${minutes % 60}m';
Color shiftTemplatesScreenColor(String value) {
  final hex = value.replaceFirst('#', '');
  final parsed = hex.length == 6 ? int.tryParse('FF$hex', radix: 16) : null;
  return parsed == null ? AppColors.ink : Color(parsed);
}

String shiftTemplatesScreenSupportMessage(String message, String? requestId) =>
    requestId == null ? message : '$message\nSupport reference: $requestId';
