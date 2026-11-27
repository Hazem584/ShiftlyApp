import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class EmployeeScheduleWeekHeader extends StatelessWidget {
  const EmployeeScheduleWeekHeader({
    required this.firstDay,
    required this.lastDay,
    required this.month,
    required this.timezone,
    required this.busy,
    required this.onMove,
    super.key,
  });

  final int firstDay;
  final int lastDay;
  final DateTime month;
  final String timezone;
  final bool busy;
  final ValueChanged<int> onMove;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return Row(
      children: [
        Expanded(
          child: Text(
            '$firstDay–$lastDay ${DateFormat.yMMMM(locale).format(month)} · $timezone',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        IconButton(
          tooltip: context.tr('Previous week'),
          onPressed: busy ? null : () => onMove(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          tooltip: context.tr('Next week'),
          onPressed: busy ? null : () => onMove(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
