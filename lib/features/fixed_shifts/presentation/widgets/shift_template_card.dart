import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/clock_time.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';

import 'shift_template_details.dart';

class ShiftTemplateCard extends StatelessWidget {
  const ShiftTemplateCard({
    super.key,
    required this.template,
    required this.busy,
    required this.onEdit,
    required this.onArchive,
  });
  final ShiftTemplate template;
  final bool busy;
  final VoidCallback onEdit, onArchive;
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return SurfaceCard(
      key: Key('shift-template-${template.id}'),
      onTap: busy
          ? null
          : () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => InheritedTheme.captureAll(
                  context,
                  ShiftTemplateDetails(
                    template: template,
                    onEdit: template.active ? onEdit : null,
                    onArchive: template.active ? onArchive : null,
                  ),
                ),
              ),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.schedule_outlined),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  '${ClockTime.minutes(template.startMinute, locale: locale)} – ${ClockTime.minutes(template.endMinute, locale: locale)}',
                  textDirection: TextDirection.ltr,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (template.overnight)
                  Text(
                    context.tr('Overnight / next-day end'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (!template.active)
                  Text(
                    context.tr('Archived'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (busy) const LinearProgressIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
