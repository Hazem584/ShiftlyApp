import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class WorkWeekStrip extends StatelessWidget {
  const WorkWeekStrip({required this.date, super.key});
  final String date;
  @override
  Widget build(BuildContext context) {
    // Calendar dates use UTC arithmetic so DST cannot repeat or skip a day.
    final parsed = DateTime.parse(date);
    final today = DateTime.utc(parsed.year, parsed.month, parsed.day);
    final colors = Theme.of(context).colorScheme;
    final first = today.subtract(Duration(days: today.weekday - 1));
    final locale = Localizations.localeOf(context).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr('This week'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/employee?tab=shifts'),
              child: Text(context.tr('Full schedule')),
            ),
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < 7; i++)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Container(
                    width: 48,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: first.add(Duration(days: i)).day == today.day
                          ? colors.primary
                          : colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: DefaultTextStyle(
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: first.add(Duration(days: i)).day == today.day
                            ? colors.onPrimary
                            : colors.onSurfaceVariant,
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormat.E(locale)
                                .format(first.add(Duration(days: i))),
                            style: const TextStyle(fontSize: 10),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat.d(locale)
                                .format(first.add(Duration(days: i))),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}
