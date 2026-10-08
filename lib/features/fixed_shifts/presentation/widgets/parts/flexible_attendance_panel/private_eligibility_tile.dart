part of '../../flexible_attendance_panel.dart';

class _EligibilityTile extends StatelessWidget {
  const _EligibilityTile({
    required this.entry,
    required this.timezone,
    required this.busy,
    this.onTap,
  });
  final EligibleShiftOccurrence entry;
  final String timezone;
  final bool busy;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final status = _classification(entry.classification);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: entry.recommended
            ? Theme.of(context).colorScheme.primaryContainer
            : AppColors.field,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: entry.recommended
              ? Theme.of(context).colorScheme.primary
              : AppColors.borderColor,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          key: Key('eligible-template-${entry.template.id}'),
          onTap: busy ? null : onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          leading: Container(
            width: 8,
            height: 52,
            decoration: BoxDecoration(
              color: _color(entry.template.color),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  entry.template.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (entry.recommended)
                const Chip(
                  label: Text('Recommended'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          subtitle: Text(
            '${WorkspaceTime.time(entry.scheduledStartAt, timezone, locale: Localizations.localeOf(context).toString())} – ${WorkspaceTime.time(entry.scheduledEndAt, timezone, locale: Localizations.localeOf(context).toString())}\n${entry.operationalDate} • $status${entry.lateMinutes > 0 ? ' • ${entry.lateMinutes} min late' : ''}',
          ),
          trailing: busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_classificationIcon(entry.classification)),
          isThreeLine: true,
        ),
      ),
    );
  }
}
