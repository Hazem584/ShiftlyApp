import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/clock_time.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/shift_template.dart';

/// Schedule information only; a cached template never grants clock-in access.
class SavedScheduleList extends StatelessWidget {
  const SavedScheduleList({required this.templates, super.key});
  final List<ShiftTemplate> templates;
  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context).locale.languageCode;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              context.tr('Your saved schedule'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final template in templates.where((item) => item.active))
            ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: Text(template.name),
              subtitle: Text(
                '${ClockTime.minutes(template.startMinute, locale: locale)} – ${ClockTime.minutes(template.endMinute, locale: locale)}',
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              context.tr('Connect and refresh before recording attendance.'),
            ),
          ),
        ],
      ),
    );
  }
}
