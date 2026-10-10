import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/points/domain/entities/points_models.dart';

String monthLabel(DateTime value, [BuildContext? context]) {
  if (context != null) {
    return DateFormat.yMMMM(Localizations.localeOf(context).toString())
        .format(value);
  }
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[value.month - 1]} ${value.year}';
}

String pointLabel(PointType type) => switch (type) {
  PointType.green => 'GREEN',
  PointType.black => 'BLACK',
  PointType.red => 'RED',
  PointType.orange => 'ORANGE',
  PointType.blue => 'BLUE',
  PointType.unknown => 'Points',
};

IconData pointIcon(PointType type) => switch (type) {
  PointType.green => Icons.eco,
  PointType.black => Icons.timelapse,
  PointType.red => Icons.error_outline,
  PointType.orange => Icons.pending_actions,
  PointType.blue => Icons.volunteer_activism,
  PointType.unknown => Icons.help_outline,
};

String reasonLabel(String value) => value
    .toLowerCase()
    .split('_')
    .map(
      (part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}',
    )
    .join(' ');

String statusLabel(PerformanceStatus? status) => switch (status) {
  PerformanceStatus.present => 'Present',
  PerformanceStatus.late => 'Late',
  PerformanceStatus.absent => 'Absent',
  PerformanceStatus.incomplete => 'Incomplete',
  PerformanceStatus.excused => 'Excused',
  PerformanceStatus.dayOff => 'Day off',
  PerformanceStatus.pending => 'Pending',
  PerformanceStatus.unknown => 'Unknown',
  null => 'No status',
};

IconData statusIcon(PerformanceStatus status) => switch (status) {
  PerformanceStatus.present => Icons.check_circle_outline,
  PerformanceStatus.late => Icons.schedule,
  PerformanceStatus.absent => Icons.cancel_outlined,
  PerformanceStatus.incomplete => Icons.timelapse,
  PerformanceStatus.excused => Icons.favorite_outline,
  PerformanceStatus.dayOff => Icons.weekend_outlined,
  PerformanceStatus.pending => Icons.more_time,
  PerformanceStatus.unknown => Icons.help_outline,
};

Color statusColor(BuildContext context, PerformanceStatus? status) =>
    switch (status) {
      PerformanceStatus.present => Colors.green,
      PerformanceStatus.late => Colors.orange,
      PerformanceStatus.absent => Theme.of(context).colorScheme.error,
      PerformanceStatus.incomplete => Colors.deepOrange,
      PerformanceStatus.excused => Colors.purple,
      PerformanceStatus.dayOff => Colors.blueGrey,
      PerformanceStatus.pending ||
      PerformanceStatus.unknown ||
      null => Theme.of(context).colorScheme.outline,
    };

Widget detailRow(BuildContext context, String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 5),
  child: Row(
    children: [
      Expanded(child: Text(context.tr(label))),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ],
  ),
);
