import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';
import 'package:shiftly/features/reports/presentation/attendance_reports_cubit.dart';

List<Widget> buildReportFailureBanner(
  BuildContext context,
  String message, {
  required bool busy,
  required VoidCallback onRefresh,
}) => [
  const SizedBox(height: 16),
  Text(context.tr(message)),
  Align(
    alignment: AlignmentDirectional.centerStart,
    child: FilledButton.icon(
      onPressed: busy ? null : onRefresh,
      icon: const Icon(Icons.refresh),
      label: Text(context.tr('Refresh report')),
    ),
  ),
];

List<Widget> buildReportPeriodControls(
  BuildContext context, {
  required AttendanceReportsState state,
  required bool busy,
  required VoidCallback onChooseRange,
}) {
  final cubit = context.read<AttendanceReportsCubit>();
  return [
    Text(
      context.tr('Weekly and monthly attendance, lateness and work hours'),
      style: Theme.of(context).textTheme.bodyLarge,
    ),
    const SizedBox(height: 16),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(context.tr('Weekly')),
          selected: state.period == ReportPeriod.weekly,
          onSelected: busy
              ? null
              : (_) => cubit.selectPeriod(ReportPeriod.weekly),
        ),
        ChoiceChip(
          label: Text(context.tr('Monthly')),
          selected: state.period == ReportPeriod.monthly,
          onSelected: busy
              ? null
              : (_) => cubit.selectPeriod(ReportPeriod.monthly),
        ),
        ActionChip(
          label: Text(context.tr('Choose period')),
          avatar: const Icon(Icons.date_range),
          onPressed: busy ? null : onChooseRange,
        ),
      ],
    ),
    const SizedBox(height: 8),
    Row(
      children: [
        IconButton(
          tooltip: context.tr('Previous period'),
          onPressed: busy ? null : () => cubit.move(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            state.range?.label ?? '',
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
          ),
        ),
        IconButton(
          tooltip: context.tr('Next period'),
          onPressed: busy ? null : () => cubit.move(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    ),
    if (state.period == ReportPeriod.weekly)
      Text(context.tr('Weeks run Saturday through Friday.')),
  ];
}
