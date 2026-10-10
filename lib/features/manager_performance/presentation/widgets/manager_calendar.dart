import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_performance_cubit.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_resource_state.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_scoped_details.dart';
import 'package:shiftly/features/points/domain/entities/points_models.dart';
import 'package:shiftly/features/points/presentation/widgets/points_formatters.dart';

class ManagerCalendar extends StatelessWidget {
  const ManagerCalendar({
    required this.month,
    required this.state,
    required this.timezone,
    required this.changeMonth,
    required this.cubit,
    required this.scope,
    super.key,
  });
  final DateTime month;
  final ManagerPerformanceCubit cubit;
  final FeatureSessionScope? scope;
  final ManagerResourceState state;
  final String timezone;
  final void Function(DateTime) changeMonth;
  @override
  Widget build(BuildContext context) {
    final days = {
      for (final record in state.records)
        record.id: PerformanceDay.fromJson(record.fields),
    };
    final offset = DateTime(month.year, month.month).weekday - 1;
    final count = DateTime(month.year, month.month + 1, 0).day;
    final dayTextStyle = DefaultTextStyle.of(context).style;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(monthLabel(month, context))),
            IconButton(
              tooltip: context.tr('Previous month'),
              onPressed: month.year == 2000 && month.month == 1
                  ? null
                  : () => changeMonth(DateTime(month.year, month.month - 1)),
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: context.tr('Next month'),
              onPressed: month.year == 2100 && month.month == 12
                  ? null
                  : () => changeMonth(DateTime(month.year, month.month + 1)),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        if (state.loading) const LinearProgressIndicator(),
        if (state.error != null) Text(context.tr(state.error!)),
        LayoutBuilder(
          builder: (context, constraints) {
            // Measure the actual scaled line height, including wrapping in a
            // narrow cell, rather than treating scaled font size as its height.
            var dateHeight = 0.0;
            for (var number = 1; number <= count; number++) {
              final painter = TextPainter(
                text: TextSpan(
                  text: context.tr('{value1}', {'value1': (number).toString()}),
                  style: dayTextStyle,
                ),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
                locale: Localizations.localeOf(context),
              )..layout(maxWidth: constraints.maxWidth / 7);
              dateHeight = math.max(dateHeight, painter.height);
              painter.dispose();
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: count + offset,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: math.max(48, dateHeight + 18 + 12),
              ),
              itemBuilder: (context, index) {
                if (index < offset) {
                  return const SizedBox.shrink();
                }
                final date =
                    '${month.year}-${month.month.toString().padLeft(2, '0')}-${(index - offset + 1).toString().padLeft(2, '0')}';
                final day = days[date];
                return Semantics(
                  label: context.tr('{value1}, {value2}', {
                    'value1': (date).toString(),
                    'value2': (context.tr(statusLabel(day?.status))).toString(),
                  }),
                  child: InkWell(
                    onTap: day == null
                        ? null
                        : () => showDialog<void>(
                            context: context,
                            builder: (context) => ManagerScopedDetails(
                              cubit: cubit,
                              scope: scope,
                              child: AlertDialog(
                                title: Text(day.date.value),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(context.tr(statusLabel(day.status))),
                                      if (day.templateName != null)
                                        Text(day.templateName!),
                                      if (day.clockInAt != null)
                                        Text(
                                          context.tr('Clock-in: {value1}', {
                                            'value1': (WorkspaceTime.dateTime(
                                              day.clockInAt!,
                                              timezone,
                                              locale: Localizations.localeOf(
                                                context,
                                              ).toString(),
                                            )).toString(),
                                          }),
                                        ),
                                      if (day.clockOutAt != null)
                                        Text(
                                          context.tr('Clock-out: {value1}', {
                                            'value1': (WorkspaceTime.dateTime(
                                              day.clockOutAt!,
                                              timezone,
                                              locale: Localizations.localeOf(
                                                context,
                                              ).toString(),
                                            )).toString(),
                                          }),
                                        ),
                                      if (day.workDurationMinutes != null)
                                        Text(
                                          context.tr(
                                            'Worked {value1} minutes',
                                            {
                                              'value1':
                                                  (day.workDurationMinutes)
                                                      .toString(),
                                            },
                                          ),
                                        ),
                                      if (day.lateMinutes != null)
                                        Text(
                                          context.tr('Late {value1} minutes', {
                                            'value1': (day.lateMinutes)
                                                .toString(),
                                          }),
                                        ),
                                      for (final change in day.pointChanges)
                                        Text(
                                          context.tr('{value1} {value2}', {
                                            'value1': context.tr(
                                              pointLabel(change.type),
                                            ),
                                            'value2': (change.amount)
                                                .toString(),
                                          }),
                                        ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(context.tr('Close')),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.tr('{value1}', {
                            'value1': (index - offset + 1).toString(),
                          }),
                          style: dayTextStyle,
                          textAlign: TextAlign.center,
                        ),
                        if (day != null)
                          Icon(
                            statusIcon(day.status),
                            size: 18,
                            color: statusColor(context, day.status),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final status in PerformanceStatus.values)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon(status), size: 18),
                  const SizedBox(width: 4),
                  Flexible(child: Text(context.tr(statusLabel(status)))),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
