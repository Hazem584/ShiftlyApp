import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/clock_time.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';

class ShiftTemplateDetails extends StatelessWidget {
  const ShiftTemplateDetails({
    required this.template,
    required this.onEdit,
    required this.onArchive,
    super.key,
  });
  final ShiftTemplate template;
  final VoidCallback? onEdit, onArchive;
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final start = ClockTime.minutes(template.startMinute, locale: locale);
    final end = ClockTime.minutes(template.endMinute, locale: locale);
    return Scaffold(
      appBar: AppBar(title: Text(template.name)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              context.tr(
                template.active ? 'Active template' : 'Archived template',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 32),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$start – $end',
                    style: Theme.of(context).textTheme.titleMedium,
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr(
                      template.overnight
                          ? 'Overnight / next-day end'
                          : 'Same-day shift',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('Check-in policy'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('{minutes}m grace', {
                      'minutes': template.graceMinutes.toString(),
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('{minutes}m early', {
                      'minutes': template.allowedEarlyCheckInMinutes.toString(),
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('{minutes}m late', {
                      'minutes': template.allowedLateCheckInMinutes.toString(),
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('Minimum work: {minutes} minutes', {
                      'minutes': template.minimumWorkMinutes.toString(),
                    }),
                  ),
                ],
              ),
            ),
            if (template.description?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Description'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(template.description!),
                  ],
                ),
              ),
            ],
            if (onEdit != null) ...[
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  onEdit!();
                },
                child: Text(context.tr('Edit template')),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onArchive?.call();
                },
                child: Text(context.tr('Archive template')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
