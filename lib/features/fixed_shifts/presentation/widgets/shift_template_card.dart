import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/utils/clock_time.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/utils/shift_templates_formatters.dart';

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
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final color = shiftTemplatesScreenColor(template.color);
    return Opacity(
      opacity: template.active ? 1 : .68,
      child: SurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    template.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: _badge(
                template.active
                    ? Icons.check_circle_outline
                    : Icons.archive_outlined,
                context.tr(template.active ? 'Active' : 'Archived'),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.tr('{value1} – {value2}  •  {value3}', {
                'value1': (ClockTime.minutes(
                  template.startMinute,
                  locale: Localizations.localeOf(context).toString(),
                )).toString(),
                'value2': (ClockTime.minutes(
                  template.endMinute,
                  locale: Localizations.localeOf(context).toString(),
                )).toString(),
                'value3': (shiftTemplatesScreenDuration(
                  template.durationMinutes,
                  context,
                )).toString(),
              }),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (template.overnight)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Row(
                  children: [
                    const Icon(Icons.nights_stay_outlined, size: 15),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(context.tr('Overnight / next-day end')),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 9),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _policy(
                  Icons.hourglass_top_rounded,
                  context.tr('{minutes}m grace', {
                    'minutes': '${template.graceMinutes}',
                  }),
                ),
                _policy(
                  Icons.login_rounded,
                  context.tr('{minutes}m early', {
                    'minutes': '${template.allowedEarlyCheckInMinutes}',
                  }),
                ),
                _policy(
                  Icons.more_time_rounded,
                  context.tr('{minutes}m late', {
                    'minutes': '${template.allowedLateCheckInMinutes}',
                  }),
                ),
                _policy(
                  Icons.timer_outlined,
                  context.tr('{duration} minimum', {
                    'duration': shiftTemplatesScreenDuration(
                      template.minimumWorkMinutes,
                      context,
                    ),
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 4,
              runSpacing: 4,
              children: [
                if (template.active) ...[
                  TextButton.icon(
                    onPressed: busy ? null : onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(context.tr('Edit')),
                  ),
                  TextButton.icon(
                    onPressed: busy ? null : onArchive,
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.archive_outlined),
                    label: Text(context.tr('Archive')),
                  ),
                ] else
                  Text(
                    context.tr('Read-only history'),
                    style: TextStyle(
                      color: AppPalette.of(context).textSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _policy(IconData icon, String text) => _badge(icon, text);

  Widget _badge(IconData icon, String text) => Builder(
    builder: (context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppPalette.of(context).field,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppPalette.of(context).borderColor),
      ),
      child: Wrap(
        spacing: 5,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [Icon(icon, size: 15), Text(text)],
      ),
    ),
  );
}
